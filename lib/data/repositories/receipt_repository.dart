import 'package:biedronka_expenses/data/database.dart';
import 'package:biedronka_expenses/domain/models/receipt.dart';
import 'package:biedronka_expenses/domain/models/line_item.dart';
import 'package:biedronka_expenses/domain/models/monthly_total.dart';

class ReceiptRepository {
  Future<List<Receipt>> getAllReceipts() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('receipts', orderBy: 'purchase_ts DESC');
    return maps.map((map) => Receipt.fromMap(map)).toList();
  }

  Future<List<Receipt>> getReceiptsByMonth(int year, int month) async {
    final db = await DatabaseHelper.database;
    final startOfMonth = DateTime(year, month).millisecondsSinceEpoch;
    final startOfNextMonth = DateTime(year, month + 1).millisecondsSinceEpoch;
    
    final maps = await db.query(
      'receipts',
      where: 'purchase_ts >= ? AND purchase_ts < ?',
      whereArgs: [startOfMonth, startOfNextMonth],
      orderBy: 'purchase_ts DESC',
    );
    
    return maps.map((map) => Receipt.fromMap(map)).toList();
  }

  Future<Receipt?> getReceipt(String id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('receipts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Receipt.fromMap(maps.first);
  }

  Future<String> insertReceipt(Receipt receipt) async {
    final db = await DatabaseHelper.database;
    await db.insert('receipts', receipt.toMap());
    return receipt.id;
  }

  Future<void> updateReceipt(Receipt receipt) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'receipts',
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  Future<void> deleteReceipt(String id) async {
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('line_items', where: 'receipt_id = ?', whereArgs: [id]);
      await txn.delete('receipts', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<LineItem>> getLineItemsForReceipt(String receiptId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'line_items',
      where: 'receipt_id = ?',
      whereArgs: [receiptId],
    );
    return maps.map((map) => LineItem.fromMap(map)).toList();
  }

  Future<void> insertLineItems(List<LineItem> items) async {
    final db = await DatabaseHelper.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert('line_items', item.toMap());
    }
    await batch.commit();
  }

  Future<List<MonthlyTotal>> getMonthlyTotals(int months) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'monthly_totals',
      orderBy: 'year DESC, month DESC',
      limit: months,
    );
    return maps.map((map) => MonthlyTotal.fromMap(map)).toList();
  }

  Future<Receipt?> getMaxReceiptForMonth(int year, int month) async {
    final db = await DatabaseHelper.database;
    final startOfMonth = DateTime(year, month).millisecondsSinceEpoch;
    final startOfNextMonth = DateTime(year, month + 1).millisecondsSinceEpoch;
    
    final maps = await db.query(
      'receipts',
      where: 'purchase_ts >= ? AND purchase_ts < ?',
      whereArgs: [startOfMonth, startOfNextMonth],
      orderBy: 'total_gross DESC',
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return Receipt.fromMap(maps.first);
  }

  Future<bool> receiptExists(String fileHash) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      'receipts',
      where: 'file_hash = ?',
      whereArgs: [fileHash],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> updateAggregates() async {
    final db = await DatabaseHelper.database;
    
    // Update monthly totals
    await db.execute('DELETE FROM monthly_totals');
    await db.execute('''
      INSERT INTO monthly_totals (year, month, total)
      SELECT 
        CAST(strftime('%Y', purchase_ts/1000, 'unixepoch') AS INTEGER) as year,
        CAST(strftime('%m', purchase_ts/1000, 'unixepoch') AS INTEGER) as month,
        SUM(total_gross) as total
      FROM receipts
      GROUP BY year, month
    ''');

    // Update category month totals
    await db.execute('DELETE FROM category_month_totals');
    await db.execute('''
      INSERT INTO category_month_totals (category_id, year, month, total)
      SELECT 
        li.category_id,
        CAST(strftime('%Y', r.purchase_ts/1000, 'unixepoch') AS INTEGER) as year,
        CAST(strftime('%m', r.purchase_ts/1000, 'unixepoch') AS INTEGER) as month,
        SUM(li.total) as total
      FROM line_items li
      JOIN receipts r ON li.receipt_id = r.id
      GROUP BY li.category_id, year, month
    ''');
  }
}