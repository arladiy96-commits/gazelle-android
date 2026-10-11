import '../lib/models/statistics_month_comparison.dart';

// Standalone calendar regression checks: dart run scripts/check_statistics_month_comparison.dart
void main() {
  var checks = 0;
  void check(bool condition, String label) {
    if (!condition) throw StateError(label);
    checks++;
  }

  StatisticsMonthComparison compare(
    int year,
    int month,
    int day,
    int previousYear,
    int previousMonth,
  ) => StatisticsMonthComparison(
    month: DateTime(year, month),
    comparisonMonth: DateTime(previousYear, previousMonth),
    today: DateTime(year, month, day),
  );

  final eleven = compare(2026, 10, 11, 2026, 9);
  check(eleven.start == DateTime(2026, 10, 1), 'Starts on first');
  check(eleven.end == DateTime(2026, 10, 11), 'October through 11');
  check(eleven.previousEnd == DateTime(2026, 9, 11), 'September through 11');
  final twelve = compare(2026, 10, 12, 2025, 5);
  check(twelve.previousEnd == DateTime(2025, 5, 12), 'Any earlier month/year');
  check(twelve.days == 12, 'Next day advances');
  final january = compare(2027, 1, 1, 2026, 12);
  check(january.previousEnd == DateTime(2026, 12, 1), 'Year rollover');
  final february = compare(2026, 3, 31, 2026, 2);
  check(february.end == DateTime(2026, 3, 28), 'Equal length in March');
  check(
    february.previousEnd == DateTime(2026, 2, 28),
    'No overflow into March',
  );
  final leap = compare(2024, 3, 31, 2024, 2);
  check(leap.days == 29, 'Leap February');
  final historical = StatisticsMonthComparison(
    month: DateTime(2026, 8),
    comparisonMonth: DateTime(2026, 6),
    today: DateTime(2026, 10, 11),
  );
  check(historical.end == DateTime(2026, 8, 11), 'Historical same-day cutoff');
  final entries = <DateTime, double>{
    DateTime(2026, 10, 1): 12000,
    DateTime(2026, 10, 11): 8000,
    DateTime(2026, 10, 12): 9000,
    DateTime(2026, 9, 11): 25000,
    DateTime(2026, 9, 12): 7000,
  };
  double sum(DateTime start, DateTime end) => entries.entries
      .where((e) => !e.key.isBefore(start) && !e.key.isAfter(end))
      .fold(0.0, (value, e) => value + e.value);
  check(
    sum(eleven.start, eleven.end) == 20000,
    'Cutoff includes day 11, excludes 12',
  );
  check(
    sum(eleven.previousStart, eleven.previousEnd) == 25000,
    'Comparable history',
  );
  var rejected = false;
  try {
    StatisticsMonthComparison(
      month: DateTime(2026, 11),
      comparisonMonth: DateTime(2026, 9),
      today: DateTime(2026, 10, 11),
    );
  } on ArgumentError {
    rejected = true;
  }
  check(rejected, 'Reject future months');
  print('$checks calendar checks passed');
}
