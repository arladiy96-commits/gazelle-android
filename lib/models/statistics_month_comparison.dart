/// Calendar windows independent of storage/API. End dates are inclusive.
/// Supply the user's local calendar date, not a UTC server timestamp.
class StatisticsMonthComparison {
  final DateTime start;
  final DateTime previousStart;
  final int days;

  factory StatisticsMonthComparison({
    required DateTime month,
    required DateTime comparisonMonth,
    required DateTime today,
  }) {
    final start = DateTime(month.year, month.month);
    final previous = DateTime(comparisonMonth.year, comparisonMonth.month);
    final currentMonth = DateTime(today.year, today.month);
    if (start.isAfter(currentMonth) || previous.isAfter(currentMonth)) {
      throw ArgumentError('Cannot compare future months');
    }
    var days = today.day;
    for (final value in [start, previous]) {
      final length = DateTime(value.year, value.month + 1, 0).day;
      if (length < days) days = length;
    }
    return StatisticsMonthComparison._(start, previous, days);
  }

  const StatisticsMonthComparison._(this.start, this.previousStart, this.days);
  DateTime get end => DateTime(start.year, start.month, days);
  DateTime get previousEnd =>
      DateTime(previousStart.year, previousStart.month, days);
}
