import 'dart:convert';
import 'dart:math';
import 'package:biedronka_expenses/domain/models/receipt.dart';
import 'package:biedronka_expenses/domain/models/line_item.dart';
import 'package:biedronka_expenses/domain/models/monthly_total.dart';

class DemoData {
  static String generateId() {
    final random = Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).substring(0, 22);
  }

  static List<MonthlyTotal> getMonthlyTotals() {
    return [
      const MonthlyTotal(year: 2024, month: 10, total: 820.0),
      const MonthlyTotal(year: 2024, month: 11, total: 910.0),
      const MonthlyTotal(year: 2024, month: 12, total: 760.0),
      const MonthlyTotal(year: 2025, month: 1, total: 1200.0),
      const MonthlyTotal(year: 2025, month: 2, total: 980.0),
      const MonthlyTotal(year: 2025, month: 3, total: 1100.0),
      const MonthlyTotal(year: 2025, month: 4, total: 870.0),
      const MonthlyTotal(year: 2025, month: 5, total: 1050.0),
      const MonthlyTotal(year: 2025, month: 6, total: 990.0),
      const MonthlyTotal(year: 2025, month: 7, total: 1130.0),
      const MonthlyTotal(year: 2025, month: 8, total: 1250.0),
      const MonthlyTotal(year: 2025, month: 9, total: 940.0),
    ];
  }

  static List<Receipt> getAugust2025Receipts() {
    return [
      Receipt(
        id: generateId(),
        merchantId: 'biedronka',
        purchaseTimestamp: DateTime(2025, 8, 30, 19, 12),
        totalGross: 124.30,
        totalVat: 8.20,
        fileHash: 'hash_001',
      ),
      Receipt(
        id: generateId(),
        merchantId: 'biedronka',
        purchaseTimestamp: DateTime(2025, 8, 24, 12, 5),
        totalGross: 89.50,
        totalVat: 5.95,
        fileHash: 'hash_002',
      ),
      Receipt(
        id: 'receipt_max_august',
        merchantId: 'biedronka',
        purchaseTimestamp: DateTime(2025, 8, 20, 17, 41),
        totalGross: 236.40,
        totalVat: 15.10,
        fileHash: 'hash_003',
      ),
      Receipt(
        id: generateId(),
        merchantId: 'biedronka',
        purchaseTimestamp: DateTime(2025, 8, 18, 9, 33),
        totalGross: 92.10,
        totalVat: 6.05,
        fileHash: 'hash_004',
      ),
      Receipt(
        id: generateId(),
        merchantId: 'biedronka',
        purchaseTimestamp: DateTime(2025, 8, 14, 18, 22),
        totalGross: 78.20,
        totalVat: 5.15,
        fileHash: 'hash_005',
      ),
      Receipt(
        id: generateId(),
        merchantId: 'biedronka',
        purchaseTimestamp: DateTime(2025, 8, 11, 14, 27),
        totalGross: 156.80,
        totalVat: 10.20,
        fileHash: 'hash_006',
      ),
    ];
  }

  static List<LineItem> getMaxReceiptItems() {
    final receiptId = 'receipt_max_august';
    return [
      LineItem(
        id: generateId(),
        receiptId: receiptId,
        name: 'Mleko 2%',
        quantity: 2.0,
        unit: 'szt',
        unitPrice: 3.20,
        vatRate: 0.05,
        total: 6.40,
        categoryId: 'dairy',
      ),
      LineItem(
        id: generateId(),
        receiptId: receiptId,
        name: 'Chleb pszenny',
        quantity: 1.0,
        unit: 'szt',
        unitPrice: 4.50,
        vatRate: 0.05,
        total: 4.50,
        categoryId: 'bakery',
      ),
      LineItem(
        id: generateId(),
        receiptId: receiptId,
        name: 'Ser żółty',
        quantity: 0.5,
        unit: 'kg',
        unitPrice: 29.00,
        vatRate: 0.08,
        total: 14.50,
        categoryId: 'dairy',
      ),
      LineItem(
        id: generateId(),
        receiptId: receiptId,
        name: 'RABAT promocja',
        quantity: 1.0,
        unit: 'szt',
        unitPrice: -2.00,
        discount: 2.00,
        vatRate: 0.0,
        total: -2.00,
        categoryId: 'other',
      ),
    ];
  }

  static Map<String, double> getTopCategoriesAugust2025() {
    return {
      'Produce': 310.80,
      'Meat': 265.70,
      'Dairy': 220.30,
      'Household': 180.50,
      'Bakery': 150.10,
    };
  }

  static Map<String, dynamic> getDashboardKPIs() {
    return {
      'total30d': 1243.57,
      'averageReceipt': 82.90,
      'receipts': 15,
    };
  }
}