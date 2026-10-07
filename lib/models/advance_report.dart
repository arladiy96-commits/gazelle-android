import 'calculation_settings.dart';

import 'dart:convert';

/// Money is stored as integer tiyn, quantities as thousandths of a unit.
class AdvanceRow {
  final String id, name, direction;
  final DateTime date;
  final int quantity, price;
  final String? tripId;
  const AdvanceRow({
    required this.id,
    required this.date,
    required this.name,
    required this.quantity,
    required this.price,
    this.direction = '',
    this.tripId,
  });
  bool get automatic => tripId != null;
  int get total => calculateTotal(quantity, price);
  static int calculateTotal(int quantity, int price) =>
      ((BigInt.from(quantity) * BigInt.from(price) + BigInt.from(500)) ~/
              BigInt.from(1000))
          .toInt();
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'name': name,
    'quantity': quantity,
    'price': price,
    'direction': direction,
    'tripId': tripId,
  };
  factory AdvanceRow.fromJson(Map<String, dynamic> j) => AdvanceRow(
    id: j['id'] as String,
    date: DateTime.parse(j['date'] as String),
    name: j['name'] as String,
    quantity: j['quantity'] as int,
    price: j['price'] as int,
    direction: j['direction'] as String? ?? '',
    tripId: j['tripId'] as String?,
  );
  void validate() {
    if (name.trim().isEmpty ||
        name.length > 160 ||
        quantity <= 0 ||
        quantity > 999999999 ||
        price < 0 ||
        price > 99999999999 ||
        direction.length > 120) {
      throw ArgumentError('Проверьте наименование, количество и цену');
    }
  }

  static int? parseDecimal(String raw, int decimals) {
    final text = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (!RegExp('^\\d{1,9}(\\.\\d{0,$decimals})?\$').hasMatch(text))
      return null;
    final parts = text.split('.');
    final factor = decimals == 3 ? 1000 : 100;
    return int.parse(parts[0]) * factor +
        (parts.length == 1 ? 0 : int.parse(parts[1].padRight(decimals, '0')));
  }

  static String decimal(int value, int decimals, {bool grouped = false}) {
    final n = value.abs(), factor = decimals == 3 ? 1000 : 100;
    var whole = '${n ~/ factor}';
    if (grouped)
      whole = whole.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );
    final fraction = (n % factor)
        .toString()
        .padLeft(decimals, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return '${value < 0 ? '−' : ''}$whole${fraction.isEmpty ? '' : ',$fraction'}';
  }
}

class AdvanceReport {
  final int number;
  final DateTime? start, submittedAt;
  final List<AdvanceRow> rows;
  final int? cashOverride;
  AdvanceReport({
    required this.number,
    this.start,
    this.submittedAt,
    required List<AdvanceRow> rows,
    this.cashOverride,
  }) : rows = List.unmodifiable(rows);
  int get expenses => rows.fold(0, (sum, row) => sum + row.total);
  int get received => cashOverride ?? expenses;
  int get balance => received - expenses;
  bool get automaticCash => cashOverride == null;
  String get signature => jsonEncode(toJson());
  Map<String, dynamic> toJson() => {
    'number': number,
    'start': start?.toIso8601String(),
    'submittedAt': submittedAt?.toIso8601String(),
    'cashOverride': cashOverride,
    'rows': rows.map((e) => e.toJson()).toList(),
  };
  factory AdvanceReport.fromJson(Map<String, dynamic> j) => AdvanceReport(
    number: j['number'] as int,
    start: DateTime.tryParse(j['start'] as String? ?? ''),
    submittedAt: DateTime.tryParse(j['submittedAt'] as String? ?? ''),
    cashOverride: j['cashOverride'] as int?,
    rows: (j['rows'] as List)
        .map((e) => AdvanceRow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class AdvanceLedger {
  static const destinations = {
    'кокшетау': 'Кокшетау',
    'щучинск': 'Щучинск',
    'новоишимское': 'Новоишимское',
    'саумалколь': 'Саумалколь',
  };
  final DateTime? boundary;
  final Set<String> previousTripIds;
  final List<AdvanceRow> manual;
  final int? cashOverride;
  final List<AdvanceReport> history;
  AdvanceLedger({
    this.boundary,
    Set<String> previousTripIds = const {},
    List<AdvanceRow> manual = const [],
    this.cashOverride,
    List<AdvanceReport> history = const [],
  }) : previousTripIds = Set.unmodifiable(previousTripIds),
       manual = List.unmodifiable(manual),
       history = List.unmodifiable(history);

  AdvanceReport current(Iterable<Map<String, dynamic>> records) {
    final rows = <AdvanceRow>[...manual];
    final seen = <String>{}, allowanceDays = <String>{};
    final ordered = records.toList()
      ..sort((a, b) => '${a['date']}'.compareTo('${b['date']}'));
    for (final record in ordered) {
      if (record['kind'] != 'trip') continue;
      final id = record['id'] as String?;
      final date = DateTime.tryParse(record['date'] as String? ?? '');
      if (id == null ||
          date == null ||
          !seen.add(id) ||
          previousTripIds.contains(id))
        continue;
      if (boundary != null && !date.isAfter(boundary!)) continue;
      var name = (record['direction'] as String? ?? '').trim().toLowerCase();
      name = name
          .replaceFirst(RegExp(r'^(г\.|г |город |с\.|с |село )\s*'), '')
          .trim();
      final settings = CalculationSettings.decode(
        record['calculationSettings'],
      );
      final names = (settings['allowanceDirections'] as List).map((v) => '$v');
      final matches = names.where((v) => CalculationSettings.name(v) == name);
      if (matches.isEmpty) continue;
      final direction = matches.first;
      if (settings['allowancePerDay'] == true &&
          !allowanceDays.add(CalculationSettings.day(date)))
        continue;
      rows.add(
        AdvanceRow(
          id: 'trip:$id',
          date: date,
          name: 'Суточные',
          quantity: 1000,
          price: ((settings['allowance'] as num) * 100).round(),
          direction: direction,
          tripId: id,
        ),
      );
    }
    rows.sort((a, b) {
      final date = a.date.compareTo(b.date);
      return date != 0 ? date : a.id.compareTo(b.id);
    });
    return AdvanceReport(
      number: history.length + 1,
      start: boundary ?? (rows.isEmpty ? null : rows.first.date),
      rows: rows,
      cashOverride: cashOverride,
    );
  }

  AdvanceLedger withExpense(AdvanceRow row) {
    row.validate();
    if (row.automatic)
      throw ArgumentError('Суточные редактируются в исходном рейсе');
    return AdvanceLedger(
      boundary: boundary,
      previousTripIds: previousTripIds,
      manual: [...manual.where((e) => e.id != row.id), row],
      cashOverride: cashOverride,
      history: history,
    );
  }

  AdvanceLedger withoutExpense(String id) => AdvanceLedger(
    boundary: boundary,
    previousTripIds: previousTripIds,
    manual: manual.where((e) => e.id != id).toList(),
    cashOverride: cashOverride,
    history: history,
  );
  AdvanceLedger withCash(int? value) {
    if (value != null && (value < 0 || value > 99999999999))
      throw ArgumentError('Введите сумму не меньше нуля');
    return AdvanceLedger(
      boundary: boundary,
      previousTripIds: previousTripIds,
      manual: manual,
      cashOverride: value,
      history: history,
    );
  }

  AdvanceLedger submit(
    List<Map<String, dynamic>> records,
    String expectedSignature,
    DateTime now,
  ) {
    final report = current(records);
    if (report.signature != expectedSignature)
      throw StateError(
        'Данные изменились. Проверьте отчёт и подтвердите сдачу ещё раз.',
      );
    if (report.rows.isEmpty) throw StateError('В отчёте пока нет расходов');
    final fixed = AdvanceReport(
      number: report.number,
      start: report.start,
      submittedAt: now,
      rows: report.rows,
      cashOverride: report.cashOverride,
    );
    // Exclude every existing trip, including ineligible ones: editing an old trip
    // after submission must never reintroduce it into the new report.
    return AdvanceLedger(
      boundary: now,
      previousTripIds: {
        ...previousTripIds,
        ...records
            .where((e) => e['kind'] == 'trip')
            .map((e) => e['id'])
            .whereType<String>(),
      },
      history: [fixed, ...history],
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'boundary': boundary?.toIso8601String(),
    'previousTripIds': previousTripIds.toList(),
    'manual': manual.map((e) => e.toJson()).toList(),
    'cashOverride': cashOverride,
    'history': history.map((e) => e.toJson()).toList(),
  };
  factory AdvanceLedger.decode(String? raw) {
    if (raw == null) return AdvanceLedger();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    if (j['version'] != 1)
      throw const FormatException('Неизвестная версия авансовых отчётов');
    return AdvanceLedger(
      boundary: DateTime.tryParse(j['boundary'] as String? ?? ''),
      previousTripIds: (j['previousTripIds'] as List).cast<String>().toSet(),
      manual: (j['manual'] as List)
          .map((e) => AdvanceRow.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      cashOverride: j['cashOverride'] as int?,
      history: (j['history'] as List)
          .map(
            (e) => AdvanceReport.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}
