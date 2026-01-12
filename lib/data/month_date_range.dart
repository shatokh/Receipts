class MonthDateRange {
  const MonthDateRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  int get startMs => start.millisecondsSinceEpoch;
  int get endMs => end.millisecondsSinceEpoch;

  static MonthDateRange forDate(DateTime date) {
    final normalized = DateTime(date.year, date.month);
    return MonthDateRange(
      start: normalized,
      end: DateTime(normalized.year, normalized.month + 1),
    );
  }

  static MonthDateRange forYearMonth(int year, int month) {
    final start = DateTime(year, month);
    return MonthDateRange(start: start, end: DateTime(year, month + 1));
  }
}
