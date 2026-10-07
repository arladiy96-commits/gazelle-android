/// Versioned calculation rules. Dates are local journal dates, never display text.
class CalculationSettings {
  static const defaults = <String, dynamic>{
    'workdays': [1, 2, 3, 4, 5],
    'hoursPerDay': 8.0,
    'holidays': [
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
    ],
    'workingDates': <String>[],
    'restDates': <String>[],
    'stackHoliday': true,
    'payOverNorm': false,
    'paidDirections': ['Саумалколь', 'Щучинск', 'Новоишимское'],
    'allowanceDirections': [
      'Кокшетау',
      'Щучинск',
      'Новоишимское',
      'Саумалколь',
    ],
    'allowance': 2500.0,
    'allowancePerDay': false,
    'gasReportRate': 28.0,
    'gasCalculatorRate': 28.0,
    'gasTank': 110.0,
  };
  static Map<String, dynamic> decode(Object? value) => {
    ...defaults,
    if (value is Map) ...Map<String, dynamic>.from(value),
  };
  static String name(String value) => value
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^(г\.|г |город |с\.|с |село )\s*'), '')
      .trim();
  static String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static bool holiday(Map<String, dynamic> s, DateTime d) =>
      (s['holidays'] as List).contains(day(d));
  static bool weekend(Map<String, dynamic> s, DateTime d) {
    if ((s['workingDates'] as List).contains(day(d))) return false;
    if ((s['restDates'] as List).contains(day(d))) return true;
    return !(s['workdays'] as List).contains(d.weekday);
  }

  static bool workday(Map<String, dynamic> s, DateTime d) =>
      !weekend(s, d) && !holiday(s, d);
  static double norm(Map<String, dynamic> s, DateTime month) {
    var hours = 0.0;
    for (var n = 1; n <= DateTime(month.year, month.month + 1, 0).day; n++) {
      if (workday(s, DateTime(month.year, month.month, n)))
        hours += (s['hoursPerDay'] as num).toDouble();
    }
    return hours;
  }

  static void validate(String key, Object value) {
    if (key.startsWith('maintenance.')) {
      final maxValue =
          [
            'maintenance.inspection',
            'maintenance.insurance',
            'maintenance.other_documents',
          ].contains(key)
          ? 7300
          : 1000000;
      if (value is! num ||
          !value.isFinite ||
          value < 0 ||
          value > maxValue ||
          value != value.roundToDouble())
        throw ArgumentError('Укажите целый интервал от 0 до $maxValue');
      return;
    }
    final original = defaults[key];
    if (original == null) throw ArgumentError('Неизвестный параметр');
    if (original is bool) {
      if (value is! bool) throw ArgumentError('Выберите значение');
      return;
    }
    if (original is num) {
      if (value is! num || !value.isFinite || value < 0 || value > 999999999)
        throw ArgumentError('Введите корректное неотрицательное число');
      if ((key == 'hoursPerDay' ||
              key == 'gasReportRate' ||
              key == 'gasCalculatorRate') &&
          value <= 0)
        throw ArgumentError('Значение должно быть больше нуля');
      if (key == 'hoursPerDay' && value > 24)
        throw ArgumentError('Не более 24 часов');
      return;
    }
    if (value is! List) throw ArgumentError('Укажите список');
    if (key == 'workdays') {
      if (value.isEmpty || value.any((v) => v is! int || v < 1 || v > 7))
        throw ArgumentError('Дни недели: от 1 до 7');
    } else if (key == 'holidays' ||
        key == 'workingDates' ||
        key == 'restDates') {
      for (final raw in value) {
        final d = DateTime.tryParse('$raw');
        if (d == null || day(d) != raw)
          throw ArgumentError('Даты в формате ГГГГ-ММ-ДД');
      }
    } else if (value.any(
      (v) => v is! String || v.trim().isEmpty || v.length > 120,
    ))
      throw ArgumentError('Проверьте направления');
  }
}
