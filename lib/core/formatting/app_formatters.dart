import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static NumberFormat receiptCurrency() {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: 'PLN ',
      decimalDigits: 2,
    );
  }

  static DateFormat receiptDateTime() {
    return DateFormat('yyyy-MM-dd HH:mm');
  }

  static DateFormat receiptSearchDate() {
    return DateFormat('yyyy-MM-dd');
  }
}
