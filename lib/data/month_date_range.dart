import 'package:receipts/domain/value_objects/receipt_month.dart';

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
    return forReceiptMonth(ReceiptMonth.fromDate(date));
  }

  static MonthDateRange forYearMonth(int year, int month) {
    return forReceiptMonth(ReceiptMonth(year: year, month: month));
  }

  static MonthDateRange forReceiptMonth(ReceiptMonth month) {
    return MonthDateRange(start: month.start, end: month.nextStart);
  }
}
