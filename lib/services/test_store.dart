import '../models/server_merge.dart';
import '../models/calculation_settings.dart';
import 'account_scope.dart';
import 'employee_server_api.dart';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Account-owned journal, exported through EmployeeSync. Legacy unscoped data
/// must never be silently assigned to a server user.
class TestPreferences {
  static const storageKey = 'gazelle_miniapp_sandbox_v2';
  static final revision = ValueNotifier<int>(0);
  static final _instances = <String, Future<TestPreferences>>{};
  final AccountToken _scope;
  final String _storageKey;
  final SharedPreferences _disk;
  Map<String, dynamic> _values;
  Future<void> _queue = Future<void>.value();
  TestPreferences._(this._disk, this._values, this._scope, this._storageKey);
  static Future<TestPreferences> getInstance() {
    final scope = AccountScope.capture();
    final key = '${scope.id}:${scope.generation}';
    return _instances.putIfAbsent(key, () => _open(scope));
  }

  static Future<TestPreferences> _open(AccountToken scope) async {
    final disk = await SharedPreferences.getInstance();
    scope.check();
    final key = '${storageKey}_account_${scope.id}';
    final raw = disk.getString(key);
    final values = raw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return TestPreferences._(disk, values, scope, key);
  }

  Object? get(String key) {
    _scope.check();
    final match = RegExp(r'^home_day_(\d+)_(\d+)_(\d+)_(.+)$').firstMatch(key);
    if (match != null) {
      final d = DateTime(
        int.parse(match[1]!),
        int.parse(match[2]!),
        int.parse(match[3]!),
      );
      final name = match[4];
      final b = TestState.decode(_values['journal'] as String?);
      final shifts = b.shifts.where((s) {
        final t = DateTime.parse(s['start'] as String);
        return t.year == d.year && t.month == d.month && t.day == d.day;
      }).toList();
      if (shifts.isNotEmpty) {
        switch (name) {
          case 'hours':
            return shifts.fold<double>(0, (v, s) => v + b.hours(s));
          case 'mileage':
            return shifts.fold<double>(0, (v, s) => v + b.mileage(s));
          case 'salary':
            return b.statistics(d, day: d)['salary'];
          case 'status':
            return shifts.any((s) => s['end'] == null) ? 'open' : 'completed';
          case 'odometer_start':
            return shifts.first['startKm'];
          case 'odometer_end':
            return shifts.last['currentKm'];
        }
      }
    }
    final month = RegExp(r'^home_(\d+)_(\d+)_(.+)$').firstMatch(key);
    if (month != null) {
      final d = DateTime(int.parse(month[1]!), int.parse(month[2]!));
      final b = TestState.decode(_values['journal'] as String?);
      final stats = b.statistics(d);
      return stats[month[3]] ?? _values[key];
    }
    return _values[key];
  }

  String? getString(String key) => get(key) as String?;
  bool? getBool(String key) => get(key) as bool?;
  int? getInt(String key) => (get(key) as num?)?.toInt();
  double? getDouble(String key) => (get(key) as num?)?.toDouble();
  Set<String> getKeys() {
    _scope.check();
    final keys = _values.keys.toSet();
    final b = TestState.decode(_values['journal'] as String?);
    for (final s in b.shifts) {
      final d = DateTime.parse(s['start'] as String);
      keys.add('home_day_${d.year}_${d.month}_${d.day}_status');
    }
    return keys;
  }

  Future<bool> _write(
    String? key,
    Object? value, {
    bool reset = false,
    bool merge = false,
    String? base,
  }) {
    _scope.check();
    final task = _queue.then((_) async {
      _scope.check();
      AccountScope.requireActiveWrite();
      if (merge && key != null) {
        value = jsonEncode(
          ServerMerge.merge(
            base == null ? null : jsonDecode(base),
            value == null ? null : jsonDecode(value as String),
            _values[key] == null ? null : jsonDecode(_values[key] as String),
            key,
          ),
        );
      }
      final section = key == null
          ? 'work'
          : key.startsWith('gas_')
          ? 'gas'
          : key.startsWith('advance_report')
          ? 'advance'
          : key.startsWith('maintenance')
          ? 'maintenance'
          : key.startsWith('melnitsa_money')
          ? 'money'
          : key.contains('invoice')
          ? 'invoices'
          : null;
      if (section != null) AccountScope.requireWrite(section);
      final next = reset
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(_values);
      if (key != null) {
        if (value == null) {
          next.remove(key);
        } else {
          next[key] = value;
        }
      }
      if (!await _disk.setString(_storageKey, jsonEncode(next)))
        throw StateError('Не удалось сохранить тестовые данные');
      _values = next;
      revision.value++;
      return true;
    });
    _queue = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return task;
  }

  Future<bool> setString(String k, String v) => _write(k, v);
  Future<bool> mergeString(String k, String? base, String value) =>
      _write(k, value, merge: true, base: base);
  Future<bool> setDouble(String k, double v) => _write(k, v);
  Future<bool> setInt(String k, int v) => _write(k, v);
  Future<bool> setBool(String k, bool v) => _write(k, v);
  Future<bool> remove(String k) => _write(k, null);
  Future<bool> clear() => _write(null, null, reset: true);
  static Future<void> mergeServer(Map base, Map remote) async {
    final p = await getInstance();
    final task = p._queue.then((_) async {
      p._scope.check();
      final result = await compute(_mergeSyncPreferences, [
        base,
        Map<String, dynamic>.from(p._values),
        remote,
      ]);
      p._scope.check();
      if (result == null) return;
      final merged = result.$1;
      if (!await p._disk.setString(p._storageKey, result.$2)) {
        throw StateError('Не удалось сохранить данные сервера');
      }
      p._values
        ..clear()
        ..addAll(merged);
      revision.value++;
    });
    p._queue = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    await task;
  }

  static Future<void> flushCurrent() async {
    final p = await getInstance();
    await p._queue;
  }

  @visibleForTesting
  static void resetCache() {
    _instances.clear();
  }
}

// Persist names, never enum indexes. Missing source means a legacy odometer shift.
enum MileageSource { odometer, manual, gps }

/// Rates are journal data so every salary consumer uses the same history.
class SalaryRates {
  static const defaults = <String, double>{
    'base': 190000,
    'weekend': 10000,
    'holiday': 10000,
    'paid': 3000,
    'city': 1,
    'region': 1.9,
  };
  static Map<String, double> decode(Object? value) {
    final result = Map<String, double>.of(defaults);
    if (value is Map) {
      for (final key in defaults.keys) {
        final n = value[key];
        if (n is num && n.isFinite && n >= 0) result[key] = n.toDouble();
      }
    }
    return result;
  }
}

class TestState {
  final List<Map<String, dynamic>> directions;
  static String directionKey(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  static List<Map<String, dynamic>> defaultDirections() => [
    for (final name in [
      'Султан',
      'Петрокондитер',
      'Великанова',
      'Визави',
      'Казконд',
      'Крылова',
      'Петропавловск',
    ])
      {'id': 'city:$name', 'type': 'Город', 'name': name, 'active': true},
    for (final name in [
      'Саумалколь',
      'Щучинск',
      'Новоишимское',
      'Бишкуль',
      'Пресновка',
    ])
      {'id': 'region:$name', 'type': 'Район', 'name': name, 'active': true},
  ];
  List<String> directionNames([String? type]) =>
      (directions
          .where(
            (e) => e['active'] != false && (type == null || e['type'] == type),
          )
          .map((e) => e['name'] as String)
          .toSet()
          .toList()
        ..sort());
  void migrateDirections() {
    for (final r in records.where((e) => e['kind'] == 'trip')) {
      final name = (r['direction'] as String? ?? '').trim();
      if (name.isEmpty || !['Город', 'Район'].contains(r['type'])) continue;
      var match = directions
          .where(
            (e) =>
                e['type'] == r['type'] &&
                directionKey(e['name'] as String) == directionKey(name),
          )
          .firstOrNull;
      if (match == null) {
        match = {
          'id': 'legacy:${r['type']}:$name',
          'type': r['type'],
          'name': name,
          'active': true,
        };
        directions.add(match);
      }
      r['directionId'] ??= match['id'];
    }
  }

  final List<Map<String, dynamic>> shifts, records;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> salaryRateHistory;
  final List<Map<String, dynamic>> calculationHistory;
  final Map<String, dynamic> initialCalculationSettings;
  TestState({
    List<Map<String, dynamic>>? directions,
    List<Map<String, dynamic>> shifts = const [],
    List<Map<String, dynamic>> records = const [],
    List<Map<String, dynamic>>? products,
    List<Map<String, dynamic>> salaryRateHistory = const [],
    List<Map<String, dynamic>> calculationHistory = const [],
    Map<String, dynamic> initialCalculationSettings = const {},
  }) : directions = directions ?? defaultDirections(),
       calculationHistory = [...calculationHistory],
       initialCalculationSettings = {...initialCalculationSettings},
       salaryRateHistory = [...salaryRateHistory],
       shifts = [...shifts],
       records = [...records],
       products =
           products ??
           [
             {'id': 'flour50', 'name': 'Мука, тестовый товар', 'packKg': 50.0},
             {'id': 'flour25', 'name': 'Мука, тестовый товар', 'packKg': 25.0},
             {'id': 'sugar10', 'name': 'Сахар, тестовый товар', 'packKg': 10.0},
           ];
  factory TestState.decode(String? raw) {
    if (raw == null) return TestState();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    if (j['version'] != 2)
      throw const FormatException('Неизвестная версия тестового журнала');
    List<Map<String, dynamic>> rows(String key) => [
      for (final e in j[key] as List) Map<String, dynamic>.from(e as Map),
    ];
    final state = TestState(
      directions: j['directions'] == null ? null : rows('directions'),
      shifts: rows('shifts'),
      records: rows('records'),
      products: rows('products'),
      calculationHistory: [
        for (final e in j['calculationHistory'] as List? ?? [])
          Map<String, dynamic>.from(e as Map),
      ],
      initialCalculationSettings: Map<String, dynamic>.from(
        j['initialCalculationSettings'] as Map? ?? {},
      ),
      salaryRateHistory: [
        for (final e in j['salaryRateHistory'] as List? ?? [])
          Map<String, dynamic>.from(e as Map),
      ],
    );
    state.migrateDirections();
    return state;
  }
  Map<String, dynamic> toJson() => {
    'version': 2,
    'directions': directions,
    'shifts': shifts,
    'records': records,
    'products': products,
    'salaryRateHistory': salaryRateHistory,
    'calculationHistory': calculationHistory,
    'initialCalculationSettings': initialCalculationSettings,
  };
  Map<String, dynamic> settingsAt(DateTime time) {
    var settings = CalculationSettings.decode(initialCalculationSettings);
    for (final event in calculationHistory) {
      if (!DateTime.parse(event['at'] as String).isAfter(time))
        settings = CalculationSettings.decode(event['settings']);
    }
    return settings;
  }

  Map<String, dynamic> get calculationSettings => settingsAt(DateTime.now());
  Map<String, dynamic> settingsFor(Map<String, dynamic> row) =>
      row['calculationSettings'] == null
      ? settingsAt(DateTime.parse((row['date'] ?? row['start']) as String))
      : CalculationSettings.decode(row['calculationSettings']);
  Map<String, dynamic> calendarFor(Map<String, dynamic> shift) =>
      shift['salaryCalendar'] == null
      ? settingsFor(shift)
      : CalculationSettings.decode(shift['salaryCalendar']);
  Map<String, dynamic> calendarForNewShift(DateTime date) {
    final same =
        shifts
            .where(
              (s) =>
                  dayKey(DateTime.parse(s['start'] as String)) == dayKey(date),
            )
            .toList()
          ..sort(
            (a, b) => (a['start'] as String).compareTo(b['start'] as String),
          );
    return same.isEmpty ? settingsAt(date) : calendarFor(same.first);
  }

  double normFor(Map<String, dynamic> shift) =>
      (shift['salaryNorm'] as num?)?.toDouble() ??
      CalculationSettings.norm(
        calendarFor(shift),
        DateTime.parse(shift['start'] as String),
      );
  bool weekendShift(Map<String, dynamic> shift) => CalculationSettings.weekend(
    calendarFor(shift),
    DateTime.parse(shift['start'] as String),
  );
  bool holidayShift(Map<String, dynamic> shift) => CalculationSettings.holiday(
    calendarFor(shift),
    DateTime.parse(shift['start'] as String),
  );
  bool workShift(Map<String, dynamic> shift) =>
      !weekendShift(shift) && !holidayShift(shift);
  double gasConsumption(Map<String, dynamic> shift) {
    var remaining = hasRecordedMileage(shift) ? mileage(shift) : 0.0;
    var total = 0.0;
    for (final raw in shift['gasKmBands'] as List? ?? []) {
      final band = raw as Map;
      final used = remaining
          .clamp(0, (band['km'] as num).toDouble())
          .toDouble();
      total += used * (band['rate'] as num).toDouble() / 100;
      remaining -= used;
    }
    return total +
        remaining *
            (settingsFor(shift)['gasReportRate'] as num).toDouble() /
            100;
  }

  void changeCalculationSetting(String key, Object value, DateTime now) {
    CalculationSettings.validate(key, value);
    final next = settingsAt(now), old = next[key] ?? 0;
    final working = key == 'workingDates'
        ? value as List
        : next['workingDates'] as List;
    final resting = key == 'restDates'
        ? value as List
        : next['restDates'] as List;
    if (working.any(resting.contains))
      throw ArgumentError('Одна дата не может быть и рабочей, и выходной');
    if (jsonEncode(old) == jsonEncode(value)) return;
    for (final record in records) {
      record['calculationSettings'] ??= settingsFor(record);
    }
    for (final shift in shifts) {
      shift['calculationSettings'] ??= settingsFor(shift);
      shift['salaryCalendar'] ??= calendarFor(shift);
      shift['salaryNorm'] ??= normFor(shift);
      if (shift['end'] == null && key == 'gasReportRate') {
        final bands = [
          for (final e in shift['gasKmBands'] as List? ?? [])
            Map<String, dynamic>.from(e as Map),
        ];
        final used = bands.fold<double>(
          0,
          (v, e) => v + (e['km'] as num).toDouble(),
        );
        final km = (hasRecordedMileage(shift) ? mileage(shift) : 0.0) - used;
        if (km > 0)
          bands.add({'km': km, 'rate': settingsFor(shift)['gasReportRate']});
        shift['gasKmBands'] = bands;
        shift['calculationSettings'] = {
          ...settingsFor(shift),
          'gasReportRate': value,
        };
      }
    }
    next[key] = value;
    calculationHistory.add({
      'at': now.toIso8601String(),
      'key': key,
      'old': old,
      'value': value,
      'settings': next,
    });
  }

  Map<String, double> ratesAt(DateTime time) {
    var rates = Map<String, double>.of(SalaryRates.defaults);
    for (final change in salaryRateHistory) {
      if (!DateTime.parse(change['at'] as String).isAfter(time)) {
        rates = SalaryRates.decode(change['rates']);
      }
    }
    return rates;
  }

  Map<String, double> get currentSalaryRates => ratesAt(DateTime.now());
  Map<String, double> shiftRates(Map<String, dynamic> shift) =>
      shift['salaryRates'] == null
      ? ratesAt(DateTime.parse(shift['start'] as String))
      : SalaryRates.decode(shift['salaryRates']);
  double baseUnits(Map<String, dynamic> shift, {double? limit}) {
    var remaining = limit == null
        ? hours(shift)
        : hours(shift).clamp(0, limit).toDouble();
    var sum = 0.0;
    for (final raw in shift['salaryHourBands'] as List? ?? []) {
      final band = raw as Map;
      final used = remaining
          .clamp(0, (band['hours'] as num).toDouble())
          .toDouble();
      sum += used * (band['base'] as num).toDouble();
      remaining -= used;
    }
    return sum +
        remaining.clamp(0, double.infinity) * shiftRates(shift)['base']!;
  }

  void changeSalaryRate(String key, double value, DateTime now) {
    if (!SalaryRates.defaults.containsKey(key) ||
        !value.isFinite ||
        value < 0 ||
        value > 999999999) {
      throw ArgumentError('Введите ставку от 0 до 999 999 999');
    }
    final next = ratesAt(now);
    if (next[key] == value) return;
    // Bind all existing operations before introducing a new rate version.
    for (final record in records) {
      record['salaryRates'] ??= ratesAt(
        DateTime.parse(record['date'] as String),
      );
    }
    for (final shift in shifts) {
      shift['salaryRates'] ??= shiftRates(shift);
      shift['salaryDayRates'] ??= Map<String, double>.of(shiftRates(shift));
      if (shift['end'] == null) {
        if (key == 'base') {
          final bands = [
            for (final raw in shift['salaryHourBands'] as List? ?? [])
              Map<String, dynamic>.from(raw as Map),
          ];
          final already = bands.fold<double>(
            0,
            (sum, band) => sum + (band['hours'] as num).toDouble(),
          );
          final recorded = hours(shift) - already;
          if (recorded > 0)
            bands.add({'hours': recorded, 'base': shiftRates(shift)['base']});
          shift['salaryHourBands'] = bands;
        }
        shift['salaryRates'] = {...shiftRates(shift), key: value};
      }
    }
    next[key] = value;
    salaryRateHistory.add({'at': now.toIso8601String(), 'rates': next});
  }

  Map<String, dynamic>? get active {
    for (final s in shifts) {
      if (s['end'] == null) return s;
    }
    return null;
  }

  List<Map<String, dynamic>> forShift(String id) =>
      records.where((e) => e['shiftId'] == id).toList();
  double hours(Map<String, dynamic> s) =>
      (s['hoursWorked'] as num?)?.toDouble() ?? 0;
  double elapsed(Map<String, dynamic> s) =>
      DateTime.parse(s['end'] as String? ?? DateTime.now().toIso8601String())
          .difference(DateTime.parse(s['start'] as String))
          .inSeconds /
      3600;
  static MileageSource mileageSource(Map<String, dynamic> s) =>
      switch (s['mileageSource']) {
        'manual' => MileageSource.manual,
        'gps' => MileageSource.gps,
        _ => MileageSource.odometer,
      };
  bool hasRecordedMileage(Map<String, dynamic> s) => switch (mileageSource(s)) {
    MileageSource.manual => s['manualKm'] is num,
    MileageSource.gps => s['gpsKm'] is num,
    MileageSource.odometer => s['odometerSet'] == true,
  };
  double mileage(Map<String, dynamic> s) => switch (mileageSource(s)) {
    MileageSource.manual => (s['manualKm'] as num?)?.toDouble() ?? 0,
    MileageSource.gps => (s['gpsKm'] as num?)?.toDouble() ?? 0,
    MileageSource.odometer =>
      (s['currentKm'] as num).toDouble() - (s['startKm'] as num).toDouble(),
  };
  // Only real readings may prefill another shift or the maintenance odometer.
  double? get latestOdometer {
    final known = shifts.where((s) => s['currentKm'] is num).toList()
      ..sort((a, z) => (z['start'] as String).compareTo(a['start'] as String));
    return known.isEmpty ? null : (known.first['currentKm'] as num).toDouble();
  }

  bool inMonth(String value, DateTime d) {
    final t = DateTime.parse(value);
    return t.year == d.year && t.month == d.month;
  }

  DateTime recordDay(Map<String, dynamic> e) => DateTime.parse(
    shifts.firstWhere((s) => s['id'] == e['shiftId'])['start'] as String,
  );
  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  // Compatibility with the uploaded miniapp /api/stats calendar, not bot.py.
  static const holidays = {
    '2026-03-08',
    '2026-03-09',
    '2026-03-15',
    '2026-05-01',
    '2026-05-07',
    '2026-05-09',
    '2026-05-11',
    '2026-07-06',
    '2026-10-25',
    '2026-10-26',
    '2026-12-16',
  };
  static bool holiday(DateTime d) => holidays.contains(dayKey(d));
  static double norm(DateTime d) {
    double n = 0;
    for (int i = 1; i <= DateTime(d.year, d.month + 1, 0).day; i++) {
      final x = DateTime(d.year, d.month, i);
      if (x.weekday < 6 && !holiday(x)) n += 8;
    }
    return n;
  }

  static bool paidDirection(String value) => const {
    'саумалколь',
    'щучинск',
    'новоишимское',
  }.contains(value.trim().toLowerCase());
  Map<String, double> statistics(DateTime month, {DateTime? day}) {
    final ss = shifts.where((s) {
      final d = DateTime.parse(s['start'] as String);
      return inMonth(s['start'] as String, month) &&
          (day == null || dayKey(d) == dayKey(day));
    }).toList();
    final days = <String, DateTime>{};
    double work = 0,
        allHours = 0,
        city = 0,
        region = 0,
        km = 0,
        gas = 0,
        petrol = 0;
    double weightedBase = 0,
        weekend = 0,
        festive = 0,
        paidPay = 0,
        cityPay = 0,
        regionPay = 0;
    // Allocate the monthly cap oldest first: new hours cannot dilute old pay.
    final monthlyWork =
        shifts.where((s) {
          return inMonth(s['start'] as String, month) && workShift(s);
        }).toList()..sort(
          (a, b) => (a['start'] as String).compareTo(b['start'] as String),
        );
    var usedNorm = 0.0;
    final baseByShift = <String, double>{};
    for (final shift in monthlyWork) {
      final normal = normFor(shift);
      final unlimited = calendarFor(shift)['payOverNorm'] == true;
      final limit = unlimited
          ? hours(shift)
          : ((1 - usedNorm) * normal).clamp(0, double.infinity).toDouble();
      baseByShift[shift['id'] as String] = normal == 0
          ? 0
          : baseUnits(shift, limit: limit) / normal;
      if (normal > 0) usedNorm += hours(shift) / normal;
    }
    final calendarDays = <String, Map<String, dynamic>>{};
    final dayRates = <String, Map<String, double>>{};
    final seenMileage = <String>{};
    // Match miniapp's descending shift order and its one-mileage-per-day aggregation.
    ss.sort((a, b) => (b['start'] as String).compareTo(a['start'] as String));
    for (final shift in ss) {
      final d = DateTime.parse(shift['start'] as String);
      final key = dayKey(d);
      days[key] = d;
      calendarDays[key] = shift;
      allHours += hours(shift);
      dayRates[key] = shift['salaryDayRates'] == null
          ? shiftRates(shift)
          : SalaryRates.decode(shift['salaryDayRates']);
      if (workShift(shift)) {
        work += hours(shift);
        weightedBase += baseByShift[shift['id']] ?? 0;
      }
      if (hasRecordedMileage(shift) && seenMileage.add(key))
        km += mileage(shift);
      for (final e in forShift(shift['id'] as String)) {
        final amount = (e['amount'] as num?)?.toDouble() ?? 0;
        if (e['kind'] == 'trip') {
          final rates = e['salaryRates'] == null
              ? ratesAt(DateTime.parse(e['date'] as String))
              : SalaryRates.decode(e['salaryRates']);
          if (e['type'] == 'Город') {
            city += amount;
            cityPay += amount * rates['city']!;
          } else {
            region += amount;
            regionPay += amount * rates['region']!;
          }
          if (e['isPaid'] == true) paidPay += rates['paid']!;
        }
        if (e['kind'] == 'fuel') {
          if (e['type'] == 'Газ') {
            gas += amount;
          } else {
            petrol += amount;
          }
        }
      }
    }
    final normal = CalculationSettings.norm(
      settingsAt(
        DateTime(month.year, month.month + 1).isAfter(DateTime.now())
            ? DateTime.now()
            : DateTime(
                month.year,
                month.month + 1,
              ).subtract(const Duration(microseconds: 1)),
      ),
      month,
    );
    final base = weightedBase;
    for (final entry in days.entries) {
      final shift = calendarDays[entry.key]!;
      if (weekendShift(shift) &&
          (!holidayShift(shift) || calendarFor(shift)['stackHoliday'] == true))
        weekend += dayRates[entry.key]!['weekend']!;
      if (holidayShift(shift)) festive += dayRates[entry.key]!['holiday']!;
    }
    return {
      'salary': base + weekend + festive + paidPay + cityPay + regionPay,
      'base_salary': base,
      'weekend_pay': weekend,
      'holiday_pay': festive,
      'paid_routes_pay': paidPay,
      'city_pay': cityPay,
      'region_pay': regionPay,
      'hours': work,
      'all_hours': allHours,
      'norm_hours': normal,
      'mileage': km,
      'gas': gas,
      'petrol': petrol,
      'city_kg': city,
      'region_kg': region,
    };
  }

  double salary(Map<String, dynamic> s) {
    final d = DateTime.parse(s['start'] as String);
    return statistics(d, day: d)['salary']!;
  }
}

class TestStore {
  static final revision = TestPreferences.revision;
  static Future<void> _queue = Future<void>.value();
  static Future<void> flush() => _queue;
  static Future<void> mergeServerPreferences(Map base, Map remote) {
    final scope = AccountScope.capture();
    final task = _queue.then(
      (_) => scope.bind(() => TestPreferences.mergeServer(base, remote)),
    );
    _queue = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return task;
  }

  static Future<TestState> load() async {
    final p = await TestPreferences.getInstance();
    final b = TestState.decode(p.getString('journal'));
    b.initialCalculationSettings.putIfAbsent(
      'gasCalculatorRate',
      () => p.getDouble('gas_calculator_rate_v1') ?? 28.0,
    );
    b.initialCalculationSettings.putIfAbsent(
      'gasTank',
      () => p.getDouble('gas_calculator_tank_v1') ?? 110.0,
    );
    return b;
  }

  static Future<void> _change(TestState Function(TestState) change) {
    final scope = AccountScope.capture();
    final task = _queue.then(
      (_) => scope.bind(() async {
        AccountScope.requireActiveWrite();
        final previous = await load();
        final before =
            jsonDecode(jsonEncode(previous.toJson())) as Map<String, dynamic>;
        final next = change(previous);
        final after = next.toJson();
        for (final key in after.keys) {
          if (jsonEncode(before[key]) == jsonEncode(after[key])) continue;
          if (EmployeeServerApi.enabled &&
              const [
                'products',
                'salaryRateHistory',
                'calculationHistory',
                'initialCalculationSettings',
              ].contains(key)) {
            AccountScope.requireAdmin();
          }
          AccountScope.requireWrite(
            key == 'directions'
                ? 'directions'
                : key.toLowerCase().contains('setting') ||
                      key.toLowerCase().contains('rate')
                ? 'settings'
                : 'work',
          );
        }
        final oldShifts = (before['shifts'] as List)
            .cast<Map<String, dynamic>>();
        final oldRecords = (before['records'] as List)
            .cast<Map<String, dynamic>>();
        for (final shift in oldShifts.where((s) => s['end'] != null)) {
          final now = next.shifts
              .where((s) => s['id'] == shift['id'])
              .firstOrNull;
          final oldEntries = oldRecords
              .where((e) => e['shiftId'] == shift['id'])
              .toList();
          final newEntries = next.records
              .where((e) => e['shiftId'] == shift['id'])
              .toList();
          if (jsonEncode(shift) != jsonEncode(now) ||
              jsonEncode(oldEntries) != jsonEncode(newEntries)) {
            AccountScope.requireHistory();
          }
        }
        for (final shift in next.shifts) {
          if (shift['end'] != null &&
              !oldShifts.any((s) => s['id'] == shift['id']))
            AccountScope.requireHistory();
        }
        scope.check();
        await (await TestPreferences.getInstance()).setString(
          'journal',
          jsonEncode(next.toJson()),
        );
      }),
    );
    _queue = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return task;
  }

  static Future<List<String>> directionNames([String? type]) async =>
      (await load()).directionNames(type);
  static Future<void> saveDirection({
    String? id,
    required String type,
    required String name,
  }) => _change((b) {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (!['Город', 'Район'].contains(type) ||
        clean.isEmpty ||
        clean.length > 120)
      throw ArgumentError('Введите название до 120 символов');
    final old = b.directions.where((e) => e['id'] == id).firstOrNull;
    if (id != null && old == null) throw StateError('Направление уже удалено');
    if (old != null && old['type'] != type)
      throw ArgumentError('Категорию существующего направления менять нельзя');
    final duplicate = b.directions
        .where(
          (e) =>
              e['id'] != id &&
              e['type'] == type &&
              TestState.directionKey(e['name'] as String) ==
                  TestState.directionKey(clean),
        )
        .firstOrNull;
    if (duplicate != null && (old != null || duplicate['active'] != false))
      throw ArgumentError('Такое направление уже есть');
    if (old == null && duplicate != null) {
      duplicate['active'] = true;
      return b;
    }
    if (old != null) {
      final previous = old['name'] as String;
      for (final r in b.records) {
        if (r['directionId'] == id ||
            (r['kind'] == 'trip' &&
                r['type'] == type &&
                TestState.directionKey('${r['direction']}') ==
                    TestState.directionKey(previous))) {
          r['direction'] = clean;
          r['directionId'] = id;
        }
      }
      final sharedName = b.directions.any(
        (e) =>
            e['id'] != id &&
            CalculationSettings.name(e['name'] as String) ==
                CalculationSettings.name(previous),
      );
      // Keep name-based paid-route and allowance rules attached after rename.
      void renameRules(Map<String, dynamic> settings) {
        for (final key in ['paidDirections', 'allowanceDirections']) {
          final names = settings[key] as List?;
          if (names != null)
            settings[key] = [
              if (sharedName &&
                  names.any(
                    (n) =>
                        CalculationSettings.name('$n') ==
                        CalculationSettings.name(previous),
                  ))
                previous,
              for (final n in names)
                if (CalculationSettings.name('$n') ==
                    CalculationSettings.name(previous))
                  clean
                else
                  n,
            ];
        }
      }

      b.initialCalculationSettings.addAll(
        CalculationSettings.decode(b.initialCalculationSettings),
      );
      renameRules(b.initialCalculationSettings);
      for (final event in b.calculationHistory) {
        final settings = Map<String, dynamic>.from(event['settings'] as Map);
        renameRules(settings);
        event['settings'] = settings;
      }
      for (final r in [...b.records, ...b.shifts]) {
        if (r['calculationSettings'] is Map) {
          final settings = Map<String, dynamic>.from(
            r['calculationSettings'] as Map,
          );
          renameRules(settings);
          r['calculationSettings'] = settings;
        }
      }
      old['name'] = clean;
      old['active'] = true;
    } else {
      b.directions.add({
        'id': _id(),
        'type': type,
        'name': clean,
        'active': true,
      });
    }
    return b;
  });
  static Future<void> deleteDirection(String id) => _change((b) {
    final row = b.directions.where((e) => e['id'] == id).firstOrNull;
    if (row == null) throw StateError('Направление уже удалено');
    row['active'] = false;
    return b;
  });

  static Future<bool> isPaidDirection(String name) async =>
      ((await load()).calculationSettings['paidDirections'] as List).any(
        (v) => CalculationSettings.name('$v') == CalculationSettings.name(name),
      );
  static Future<void> setCalculationSetting(String key, Object value) =>
      _change((b) {
        AccountScope.requireWrite('settings');
        b.changeCalculationSetting(key, value, DateTime.now());
        return b;
      });
  static Future<void> setSalaryRate(String key, double value) => _change((b) {
    AccountScope.requireAdmin();
    b.changeSalaryRate(key, value, DateTime.now());
    return b;
  });
  static String _id() => DateTime.now().microsecondsSinceEpoch.toString();
  static void _km(int v) {
    if (v < 0) throw ArgumentError('Одометр не может быть отрицательным');
  }

  static Future<void> open(int? km, {double? hours, bool manual = false}) =>
      _change((b) {
        _hours(hours);
        if (b.active != null) throw StateError('Смена уже открыта');
        if (!manual) {
          if (km == null) throw ArgumentError('Введите показание одометра');
          _km(km);
          if (b.shifts.any(
            (s) => s['currentKm'] is num && (s['currentKm'] as num) > km,
          ))
            throw ArgumentError(
              'Одометр меньше предыдущего. Исправьте прошлую смену или введите больший пробег',
            );
        }
        b.shifts.add({
          'id': _id(),
          'start': DateTime.now().toIso8601String(),
          'end': null,
          'startKm': manual ? null : km,
          'currentKm': manual ? null : km,
          'mileageSource':
              (manual ? MileageSource.manual : MileageSource.odometer).name,
          'manualKm': null,
          'calculationSettings': b.calculationSettings,
          'salaryCalendar': b.calendarForNewShift(DateTime.now()),
          'salaryNorm': CalculationSettings.norm(
            b.calendarForNewShift(DateTime.now()),
            DateTime.now(),
          ),
          'salaryRates': b.currentSalaryRates,
          'salaryDayRates':
              b.shifts
                  .where(
                    (s) =>
                        TestState.dayKey(
                          DateTime.parse(s['start'] as String),
                        ) ==
                        TestState.dayKey(DateTime.now()),
                  )
                  .map((s) => s['salaryDayRates'] ?? b.shiftRates(s))
                  .firstOrNull ??
              b.currentSalaryRates,
          'hoursWorked': hours,
          'odometerSet': false,
          'gpsStatus': 'active',
          'gpsKm': 0.0,
        });
        return b;
      });
  static Future<void> odometer(
    String id,
    int km, {
    bool close = false,
    double? hours,
    MileageSource? source,
  }) => _change((b) {
    final s = b.shifts.firstWhere((s) => s['id'] == id);
    if (s['end'] != null) throw StateError('Смена уже закрыта');
    final selected = source ?? TestState.mileageSource(s);
    if (selected == MileageSource.gps)
      throw ArgumentError('GPS пока не используется для завершения смены');
    if (km < 0)
      throw ArgumentError(
        selected == MileageSource.manual
            ? 'Пробег не может быть отрицательным'
            : 'Одометр не может быть отрицательным',
      );
    _hours(hours);
    if (selected == MileageSource.manual) {
      s['manualKm'] = km;
      s['odometerSet'] = false;
    } else {
      final start = s['startKm'] as num?;
      if (start == null)
        throw ArgumentError(
          'У смены нет начального показания. Введите пробег вручную',
        );
      if (km < start) throw ArgumentError('Пробег меньше начала смены');
      s['currentKm'] = km;
      s['odometerSet'] = true;
      s['manualKm'] = null;
    }
    s['mileageSource'] = selected.name;
    if (hours != null) s['hoursWorked'] = hours;
    if (close) {
      s['end'] = DateTime.now().toIso8601String();
      s['gpsStatus'] = 'stopped';
    }
    return b;
  });
  static Future<void> saveRecord(Map<String, dynamic> value) => _change((b) {
    final e = Map<String, dynamic>.from(value);
    final kind = e['kind'];
    if (EmployeeServerApi.enabled && (kind == 'invoice' || kind == 'other')) {
      throw StateError(
        'Этот старый вид записи не подключён к серверу. Накладные добавляйте через раздел загрузки товаров.',
      );
    }
    if (!['trip', 'fuel', 'invoice', 'other'].contains(kind))
      throw ArgumentError('Неизвестная запись');
    final id = e['id'];
    final old = b.records.where((r) => r['id'] == id).firstOrNull;
    if (id != null && old == null) throw StateError('Запись уже удалена');
    e['shiftId'] = old?['shiftId'] ?? e['shiftId'] ?? b.active?['id'];
    if (e['shiftId'] == null) throw StateError('Сначала откройте смену');
    final s = b.shifts.firstWhere((s) => s['id'] == e['shiftId']);
    final d = DateTime.parse(
      e['date'] as String? ?? DateTime.now().toIso8601String(),
    );
    if (d.isAfter(DateTime.now()) ||
        d.isBefore(DateTime.parse(s['start'] as String)) ||
        (s['end'] != null && d.isAfter(DateTime.parse(s['end'] as String))))
      throw ArgumentError('Время записи должно попадать в смену');
    final amount = (e['amount'] as num?)?.toDouble() ?? 0;
    if (!amount.isFinite ||
        amount < 0 ||
        (['trip', 'fuel'].contains(kind) && amount == 0))
      throw ArgumentError('Введите число больше нуля');
    if (kind == 'trip' &&
        (!['Город', 'Район'].contains(e['type']) ||
            (e['direction'] as String? ?? '').trim().isEmpty))
      throw ArgumentError('Укажите тип и направление');
    if (kind == 'trip') {
      final name = (e['direction'] as String).trim().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      var route = b.directions
          .where(
            (r) =>
                r['type'] == e['type'] &&
                TestState.directionKey(r['name'] as String) ==
                    TestState.directionKey(name),
          )
          .firstOrNull;
      if (route?['active'] == false &&
          !(old?['directionId'] == route?['id'] && old?['type'] == e['type']))
        throw ArgumentError(
          'Направление удалено. Выберите другое или восстановите его в разделе «Направления»',
        );
      if (route == null) {
        route = {'id': _id(), 'type': e['type'], 'name': name, 'active': true};
        b.directions.add(route);
      }
      e['directionId'] = route['id'];
      e['direction'] = route['name'];
    }
    if (kind == 'fuel' && !['Газ', 'Бензин'].contains(e['type']))
      throw ArgumentError('Выберите топливо');
    if (kind == 'other' && (e['note'] as String? ?? '').trim().isEmpty)
      throw ArgumentError('Заполните описание или товары');
    if (kind == 'trip')
      e['isPaid'] =
          e['isPaid'] == true ||
          ((old == null
                      ? b.settingsAt(d)
                      : b.settingsFor(old))['paidDirections']
                  as List)
              .any(
                (name) =>
                    CalculationSettings.name('$name') ==
                    CalculationSettings.name(e['direction'] as String),
              );
    if (kind == 'invoice') {
      final matches = b.directions
          .where(
            (r) =>
                r['active'] != false &&
                TestState.directionKey(r['name'] as String) ==
                    TestState.directionKey('${e['direction'] ?? ''}'),
          )
          .toList();
      if (matches.length == 1) {
        e['directionId'] = matches.single['id'];
        e['direction'] = matches.single['name'];
      } else {
        e.remove('directionId');
      }
      if (old?['status'] == 'closed')
        throw StateError('Закрытую накладную нельзя редактировать');
      final items = [
        for (final row in e['items'] as List? ?? [])
          Map<String, dynamic>.from(row as Map),
      ];
      if (items.isEmpty) throw ArgumentError('Добавьте хотя бы один товар');
      for (final item in items) {
        final pack = (item['packKg'] as num?)?.toDouble() ?? 0;
        final weight = (item['totalKg'] as num?)?.toDouble() ?? 0;
        if ((item['name'] as String? ?? '').trim().isEmpty ||
            !pack.isFinite ||
            pack <= 0 ||
            !weight.isFinite ||
            weight <= 0)
          throw ArgumentError('Проверьте название, упаковку и вес товаров');
        item['quantity'] = (weight / pack).floor();
        if (item['quantity'] == 0)
          throw ArgumentError('Вес меньше одной упаковки');
      }
      e['items'] = items;
      e['status'] = 'draft';
      if (old == null) {
        int highest = 0;
        for (final r in b.records.where((r) => r['kind'] == 'invoice')) {
          final number = int.tryParse(r['number']?.toString() ?? '') ?? 0;
          if (number > highest) highest = number;
        }
        e['number'] = '${highest + 1}';
      }
    }
    e['calculationSettings'] =
        old?['calculationSettings'] ??
        (old == null ? b.settingsAt(d) : b.settingsFor(old));
    e['salaryRates'] =
        old?['salaryRates'] ??
        b.ratesAt(old == null ? d : DateTime.parse(old['date'] as String));
    e['amount'] = amount;
    e['id'] = id ?? _id();
    e['date'] = d.toIso8601String();
    if (old != null) b.records.remove(old);
    b.records.add(e);
    return b;
  });
  static Future<void> deleteRecord(String id) => _change((b) {
    b.records.removeWhere((e) => e['id'] == id);
    return b;
  });
  static Future<void> deleteShift(String id) => _change((b) {
    if (EmployeeServerApi.enabled)
      throw StateError(
        'Удаление серверной смены выполняется владельцем в миниаппе после проверки связанных отчётов.',
      );
    b.records.removeWhere((e) => e['shiftId'] == id);
    b.shifts.removeWhere((e) => e['id'] == id);
    return b;
  });

  /// Correct only the selected values, preserving dates, rates and other fields.
  /// All shifts are validated before the journal is written (one revision).
  static Future<void> correctShiftMetrics(
    Map<String, double> values, {
    required bool mileage,
  }) => _change((b) {
    for (final entry in values.entries) {
      final s = b.shifts.where((s) => s['id'] == entry.key).firstOrNull;
      if (s == null) throw StateError('Смена уже удалена');
      final value = entry.value;
      if (!value.isFinite ||
          value < 0 ||
          (mileage && value != value.truncateToDouble())) {
        throw ArgumentError(
          mileage
              ? 'Введите целый неотрицательный пробег'
              : 'Введите неотрицательное число часов',
        );
      }
      if (!mileage) {
        s['hoursWorked'] = value;
      } else if (TestState.mileageSource(s) == MileageSource.odometer &&
          s['startKm'] is num) {
        s['currentKm'] = (s['startKm'] as num) + value.toInt();
        s['odometerSet'] = true;
      } else {
        // A manual GPS correction must not be overwritten by incoming GPS data.
        s['mileageSource'] = MileageSource.manual.name;
        s['manualKm'] = value.toInt();
        s['odometerSet'] = false;
      }
    }
    return b;
  });

  static Future<void> editShift(
    String id,
    DateTime start,
    DateTime? end,
    int? startKm,
    int? endKm, {
    double? hours,
    int? manualKm,
  }) => _change((b) {
    final s = b.shifts.firstWhere((s) => s['id'] == id);
    final manual = TestState.mileageSource(s) == MileageSource.manual;
    _hours(hours);
    if (!manual) {
      if (startKm == null || endKm == null)
        throw ArgumentError('Введите показания одометра');
      _km(startKm);
      if (endKm < startKm) throw ArgumentError('Проверьте время и одометр');
    } else if (manualKm != null && manualKm < 0) {
      throw ArgumentError('Пробег не может быть отрицательным');
    }
    if (manual && end != null && manualKm == null && s['manualKm'] == null)
      throw ArgumentError('Введите пробег за смену');
    if (start.isAfter(DateTime.now()) ||
        (end != null && (!end.isAfter(start) || end.isAfter(DateTime.now()))))
      throw ArgumentError('Проверьте время и одометр');
    if ((s['end'] == null) != (end == null))
      throw ArgumentError('Статус смены меняется кнопкой завершения');
    for (final r in b.forShift(id)) {
      final d = DateTime.parse(r['date'] as String);
      if (d.isBefore(start) || (end != null && d.isAfter(end)))
        throw ArgumentError('За границами смены остаются записи');
    }
    for (final other in b.shifts.where((s) => s['id'] != id)) {
      final a = DateTime.parse(other['start'] as String);
      final z = other['end'] == null
          ? DateTime.now()
          : DateTime.parse(other['end'] as String);
      if (start.isBefore(z) && (end ?? DateTime.now()).isAfter(a))
        throw ArgumentError('Смены не должны пересекаться');
    }
    s.addAll({
      'start': start.toIso8601String(),
      'end': end?.toIso8601String(),
      'hoursWorked': hours ?? s['hoursWorked'],
    });
    if (manual) {
      if (manualKm != null) s['manualKm'] = manualKm;
    } else {
      s.addAll({'startKm': startKm, 'currentKm': endKm, 'odometerSet': true});
    }
    s['mileageSource'] = TestState.mileageSource(s).name;
    return b;
  });
  static void _hours(double? h) {
    if (h != null && (!h.isFinite || h < 0))
      throw ArgumentError('Введите неотрицательное число часов');
  }

  /// Exactly-once import: the counter and imported watermark share one journal
  /// write. A crash/retry, Activity recreation or repeated snapshot cannot add km twice.
  static Future<void> importGpsSnapshots(List<dynamic> snapshots) {
    final scope = AccountScope.capture();
    final task = _queue.then(
      (_) => scope.bind(() async {
        final state = await load();
        var changed = false;
        for (final raw in snapshots) {
          if (raw is! Map) continue;
          final id = raw['shiftId'];
          final token = raw['token'];
          final metres = (raw['metres'] as num?)?.toDouble();
          if (id is! String ||
              token is! String ||
              token.isEmpty ||
              metres == null ||
              !metres.isFinite ||
              metres < 0)
            continue;
          final shift = state.shifts.where((s) => s['id'] == id).firstOrNull;
          if (shift == null) continue; // Deleted shift must not be resurrected.
          final counters = Map<String, dynamic>.from(
            shift['gpsNativeCounters'] as Map? ?? {},
          );
          final previous = (counters[token] as num?)?.toDouble() ?? 0.0;
          if (metres > previous) {
            shift['gpsKm'] =
                ((shift['gpsKm'] as num?)?.toDouble() ?? 0.0) +
                (metres - previous) / 1000.0;
            counters[token] = metres;
            shift['gpsNativeCounters'] = counters;
            changed = true;
          }
          final gaps = (raw['gaps'] as num?)?.toInt() ?? 0;
          if (shift['gpsSignalGaps'] != gaps) {
            shift['gpsSignalGaps'] = gaps;
            changed = true;
          }
        }
        if (changed) {
          scope.check();
          await (await TestPreferences.getInstance()).setString(
            'journal',
            jsonEncode(state.toJson()),
          );
        }
      }),
    );
    _queue = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return task;
  }

  static Future<void> gps(String id, {bool? paused, double addKm = 0}) =>
      _change((b) {
        final s = b.shifts.firstWhere((s) => s['id'] == id);
        if (s['end'] != null) throw StateError('Смена закрыта');
        if (paused != null) s['gpsStatus'] = paused ? 'paused' : 'active';
        if (addKm > 0) {
          if (s['gpsStatus'] != 'active') throw StateError('GPS на паузе');
          s['gpsKm'] = ((s['gpsKm'] as num?)?.toDouble() ?? 0) + addKm;
        }
        return b;
      });
  static Future<void> closeInvoice(String id) => _change((b) {
    final e = b.records.firstWhere(
      (e) => e['id'] == id && e['kind'] == 'invoice',
    );
    e['status'] = 'closed';
    return b;
  });
  static Future<void> saveProduct({
    String? id,
    required String name,
    required double packKg,
  }) => _change((b) {
    if (name.trim().isEmpty || !packKg.isFinite || packKg <= 0)
      throw ArgumentError('Укажите название и вес упаковки');
    if (b.products.any(
      (p) => p['id'] != id && p['name'] == name.trim() && p['packKg'] == packKg,
    ))
      throw ArgumentError('Такой товар уже есть');
    if (id != null && !b.products.any((p) => p['id'] == id))
      throw StateError('Товар удалён');
    b.products.removeWhere((p) => p['id'] == id);
    b.products.add({'id': id ?? _id(), 'name': name.trim(), 'packKg': packKg});
    return b;
  });
  static Future<void> deleteProduct(String id) => _change((b) {
    b.products.removeWhere((p) => p['id'] == id);
    return b;
  });
  static Future<void> reset() {
    AccountScope.requireAdmin();
    final scope = AccountScope.capture();
    final task = _queue.then(
      (_) => scope.bind(() async {
        await (await TestPreferences.getInstance()).clear();
      }),
    );
    _queue = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return task;
  }

  static Future<void> seed() => _change((b) {
    AccountScope.requireAdmin();
    if (b.shifts.isNotEmpty || b.records.isNotEmpty)
      throw StateError('Пример доступен только в пустом журнале');
    final start = DateTime.now().subtract(const Duration(hours: 4));
    final id = _id();
    return TestState(
      directions: b.directions,
      salaryRateHistory: b.salaryRateHistory,
      calculationHistory: b.calculationHistory,
      initialCalculationSettings: b.initialCalculationSettings,
      shifts: [
        {
          'id': id,
          'start': start.toIso8601String(),
          'end': null,
          'startKm': 128540,
          'currentKm': 128664,
          'hoursWorked': 8.0,
          'odometerSet': true,
          'gpsStatus': 'active',
          'gpsKm': 124.0,
        },
      ],
      records: [
        {
          'id': '${id}a',
          'shiftId': id,
          'kind': 'trip',
          'type': 'Город',
          'direction': 'Петропавловск',
          'amount': 4000.0,
          'date': start.add(const Duration(minutes: 30)).toIso8601String(),
          'note': 'Тестовый рейс',
        },
        {
          'id': '${id}b',
          'shiftId': id,
          'kind': 'fuel',
          'type': 'Газ',
          'amount': 40.0,
          'date': start.add(const Duration(hours: 1)).toIso8601String(),
          'note': '',
        },
        {
          'id': '${id}c',
          'shiftId': id,
          'kind': 'trip',
          'type': 'Район',
          'direction': 'Щучинск',
          'isPaid': true,
          'amount': 2500.0,
          'date': start.add(const Duration(hours: 2)).toIso8601String(),
          'note': '',
        },
      ],
    );
  });
}

(Map<String, dynamic>, String)? _mergeSyncPreferences(List<Map> snapshots) {
  final merged = ServerMerge.mergePreferences(
    snapshots[0],
    snapshots[1],
    snapshots[2],
  );
  if (ServerMerge.same(merged, snapshots[1])) return null;
  return (merged, jsonEncode(merged));
}
