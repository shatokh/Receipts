import 'package:receipts/domain/models/monthly_total.dart';

class ReceiptMonth implements Comparable<ReceiptMonth> {
  const ReceiptMonth({
    required this.year,
    required this.month,
  });

  factory ReceiptMonth.fromDate(DateTime date) {
    return ReceiptMonth(year: date.year, month: date.month);
  }

  factory ReceiptMonth.fromMonthlyTotal(MonthlyTotal total) {
    return ReceiptMonth(year: total.year, month: total.month);
  }

  final int year;
  final int month;

  DateTime get start => DateTime(year, month);

  DateTime get nextStart => DateTime(year, month + 1);

  bool isSameMonth(DateTime date) {
    return year == date.year && month == date.month;
  }

  @override
  int compareTo(ReceiptMonth other) {
    final yearCompare = year.compareTo(other.year);
    if (yearCompare != 0) {
      return yearCompare;
    }
    return month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReceiptMonth && year == other.year && month == other.month;
  }

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';

  static List<DateTime> sortedStarts(Iterable<ReceiptMonth> months) {
    final unique = months.toSet().toList()..sort();
    return unique.map((month) => month.start).toList();
  }

  static List<DateTime> sortedStartsDescending(Iterable<ReceiptMonth> months) {
    final unique = months.toSet().toList()..sort((a, b) => b.compareTo(a));
    return unique.map((month) => month.start).toList();
  }
}
