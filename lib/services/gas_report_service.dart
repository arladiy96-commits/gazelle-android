import 'dart:convert';

import 'test_store.dart';
import 'account_scope.dart';

/// A view of the existing journal; no trips, fuel or shifts are copied to storage.
class GasReportDay {
  final DateTime date;
  final double? startKm, endKm;
  final double km, gas, petrol;
  final String directions;
  final int pending;
  final double? consumptionOverride;
  double get consumption => consumptionOverride ?? km * 28 / 100;
  const GasReportDay({
    required this.date,
    required this.startKm,
    required this.endKm,
    required this.km,
    required this.gas,
    required this.petrol,
    required this.directions,
    required this.pending,
    this.consumptionOverride,
  });
  List<Object?> get signatureValues => [
    TestState.dayKey(date),
    startKm,
    endKm,
    km,
    gas,
    petrol,
    directions,
    pending,
    if ((consumption - km * 28 / 100).abs() > 0.00000001) consumption,
  ];
}

class GasReport {
  static const rate = 28.0;
  final DateTime month;
  final String normDescription;
  final List<GasReportDay> days;
  final double? opening, fixedClosing, carriedOpening;
  final String? openingFrom, submittedSignature;
  final DateTime? submittedAt;
  final bool manualOpening;
  const GasReport({
    required this.month,
    this.normDescription = '28 л / 100 км',
    required this.days,
    required this.opening,
    required this.manualOpening,
    this.openingFrom,
    this.carriedOpening,
    this.fixedClosing,
    this.submittedSignature,
    this.submittedAt,
  });
  double get km => days.fold(0.0, (a, d) => a + d.km);
  double get gas => days.fold(0.0, (a, d) => a + d.gas);
  double get petrol => days.fold(0.0, (a, d) => a + d.petrol);
  double get consumption => days.fold(0.0, (sum, day) => sum + day.consumption);
  double? get closing => opening == null ? null : opening! + gas - consumption;
  int get pending => days.fold(0, (a, d) => a + d.pending);
  bool get submitted => submittedAt != null && fixedClosing != null;
  bool get changed => submitted && submittedSignature != signature;
  // Two independent bounded hashes of canonical derived report data. Only this
  // fingerprint is persisted, not a second copy of journal rows.
  String get signature {
    final text = jsonEncode([
      GasReportRepository.key(month),
      rate,
      opening,
      for (final d in days) d.signatureValues,
    ]);
    var a = 5381, b = 0;
    for (final c in text.codeUnits) {
      a = ((a * 33) ^ c) & 0x7fffffff;
      b = (b * 65599 + c) & 0x7fffffff;
    }
    return '${a.toRadixString(16)}:${b.toRadixString(16)}:${text.length}';
  }
}

class GasReportRepository {
  static const storageKey = 'gas_reports_v1';
  static Future<void> _queue = Future<void>.value();
  static Future<void> flush() => _queue;
  static String key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
  static Map<String, dynamic> _months(TestPreferences p) {
    final raw = p.getString(storageKey);
    if (raw == null) {
      return <String, dynamic>{};
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['version'] != 1) {
      throw const FormatException('Неизвестная версия газовых отчётов');
    }
    return Map<String, dynamic>.from(data['months'] as Map);
  }

  static Map<String, dynamic> _entry(
    Map<String, dynamic> months,
    DateTime month,
  ) => Map<String, dynamic>.from(months[key(month)] as Map? ?? const {});
  static Future<GasReport> load(DateTime month) async {
    final p = await TestPreferences.getInstance();
    return derive(await TestStore.load(), month, _months(p));
  }

  static GasReport derive(
    TestState book,
    DateTime month,
    Map<String, dynamic> months,
  ) {
    final selected = DateTime(month.year, month.month);
    final meta = _entry(months, selected),
        previous = _entry(months, DateTime(month.year, month.month - 1));
    final override = (meta['openingOverride'] as num?)?.toDouble();
    final carried = previous['submittedAt'] == null
        ? null
        : (previous['fixedClosing'] as num?)?.toDouble();
    final shifts =
        book.shifts
            .where((s) => book.inMonth(s['start'] as String, selected))
            .toList()
          ..sort(
            (a, z) => (a['start'] as String).compareTo(z['start'] as String),
          );
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final s in shifts) {
      groups
          .putIfAbsent(
            TestState.dayKey(DateTime.parse(s['start'] as String)),
            () => [],
          )
          .add(s);
    }
    final records = <String, List<Map<String, dynamic>>>{};
    for (final r in book.records) {
      records.putIfAbsent(r['shiftId'] as String, () => []).add(r);
    }
    final days = <GasReportDay>[];
    for (final group in groups.entries) {
      final ss = group.value;
      final rows = [for (final s in ss) ...?records[s['id']]]
        ..sort(
          (a, z) => (a['date']?.toString() ?? '').compareTo(
            z['date']?.toString() ?? '',
          ),
        );
      double fuel(String type) => rows
          .where((r) => r['kind'] == 'fuel' && r['type'] == type)
          .fold<double>(0, (a, r) => a + (r['amount'] as num).toDouble());
      var city = false;
      final names = <String>[], seen = <String>{};
      for (final r in rows.where((r) => r['kind'] == 'trip')) {
        if (r['type'] == 'Город') {
          city = true;
          continue;
        }
        if (r['type'] != 'Район') {
          continue;
        }
        for (final item in (r['direction']?.toString() ?? '').split(
          RegExp(r'[,;\n]'),
        )) {
          final name = item
              .split(RegExp(r'\s*(?:→|->|—|–)\s*'))
              .last
              .trim()
              .replaceAll(RegExp(r'\s+'), ' ');
          if (name.isNotEmpty && seen.add(name.toLowerCase())) {
            names.add(name);
          }
        }
      }
      final last = ss.last;
      days.add(
        GasReportDay(
          date: DateTime.parse(group.key),
          startKm: (ss.first['startKm'] as num?)?.toDouble(),
          endKm:
              TestState.mileageSource(last) == MileageSource.odometer &&
                  book.hasRecordedMileage(last)
              ? (last['currentKm'] as num?)?.toDouble()
              : null,
          km: ss.fold<double>(
            0,
            (a, s) => a + (book.hasRecordedMileage(s) ? book.mileage(s) : 0),
          ),
          consumptionOverride: ss.fold<double>(
            0,
            (sum, s) => sum + book.gasConsumption(s),
          ),
          gas: fuel('Газ'),
          petrol: fuel('Бензин'),
          directions: [if (city) 'Город', ...names].join(', '),
          pending: ss
              .where((s) => s['end'] == null || !book.hasRecordedMileage(s))
              .length,
        ),
      );
    }
    final norms = <double>{
      for (final s in shifts)
        (book.settingsFor(s)['gasReportRate'] as num).toDouble(),
      for (final s in shifts)
        for (final band in s['gasKmBands'] as List? ?? [])
          ((band as Map)['rate'] as num).toDouble(),
    };
    if (norms.isEmpty)
      norms.add((book.calculationSettings['gasReportRate'] as num).toDouble());
    final sortedNorms = norms.toList()..sort();
    return GasReport(
      normDescription:
          '${sortedNorms.map((n) => n.toString().replaceFirst(RegExp(r'\.0$'), '')).join(' / ')} л / 100 км',
      month: selected,
      days: days,
      opening: override ?? carried,
      manualOpening: override != null,
      carriedOpening: carried,
      openingFrom: override == null && carried != null
          ? key(DateTime(month.year, month.month - 1))
          : null,
      fixedClosing: (meta['fixedClosing'] as num?)?.toDouble(),
      submittedSignature: meta['signature'] as String?,
      submittedAt: DateTime.tryParse(meta['submittedAt']?.toString() ?? ''),
    );
  }

  static Future<void> _change(
    Future<void> Function(TestPreferences, Map<String, dynamic>) action,
  ) {
    final scope = AccountScope.capture();
    final task = _queue.then(
      (_) => scope.bind(() async {
        final p = await TestPreferences.getInstance(), months = _months(p);
        await action(p, months);
        await p.setString(
          storageKey,
          jsonEncode({'version': 1, 'months': months}),
        );
      }),
    );
    _queue = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return task;
  }

  static Future<void> setOpening(DateTime month, double value) =>
      _change((p, months) async {
        if (!value.isFinite || value < 0) {
          throw ArgumentError('Введите неотрицательный остаток газа');
        }
        final meta = _entry(months, month);
        meta['openingOverride'] = value;
        months[key(month)] = meta;
      });
  static Future<void> useCarry(DateTime month) => _change((p, months) async {
    final prev = _entry(months, DateTime(month.year, month.month - 1));
    if (prev['submittedAt'] == null || prev['fixedClosing'] == null) {
      throw StateError('Предыдущий отчёт ещё не сдан');
    }
    final meta = _entry(months, month)..remove('openingOverride');
    months[key(month)] = meta;
  });

  /// Initial submission and explicit re-submission share the same commit path.
  /// Next month reads this frozen closing; a dirty report never changes it.
  static Future<void> submit(
    DateTime month, {
    required String expectedSignature,
  }) => _change((p, months) async {
    final report = derive(await TestStore.load(), month, months);
    if (report.signature != expectedSignature) {
      throw StateError(
        'Данные изменились. Проверьте отчёт и подтвердите ещё раз',
      );
    }
    if (report.opening == null) {
      throw StateError('Укажите остаток с прошлого месяца');
    }
    if (report.pending > 0) {
      throw StateError('Завершите смены и укажите пробег за все дни месяца');
    }
    final meta = _entry(months, month);
    meta.addAll({
      'submittedAt': DateTime.now().toIso8601String(),
      'fixedClosing': report.closing,
      'signature': report.signature,
      'openingAtSubmission': report.opening,
    });
    months[key(month)] = meta;
  });
}
