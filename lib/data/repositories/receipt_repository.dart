import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biedronka_expenses/data/database.dart';
import 'package:biedronka_expenses/data/database_update_bus.dart';
import 'package:biedronka_expenses/data/database_update_bus_provider.dart';
import 'package:biedronka_expenses/domain/models/line_item.dart';
import 'package:biedronka_expenses/domain/models/merchant.dart';
import 'package:biedronka_expenses/domain/models/receipt.dart';
import 'package:biedronka_expenses/domain/models/receipt_details.dart';
import 'package:biedronka_expenses/domain/models/receipt_row.dart';

typedef Reader = T Function<T>(ProviderListenable<T> provider);

class ReceiptRepository {
  ReceiptRepository(Reader read) : _updateBus = read(databaseUpdateBusProvider);

  final DatabaseUpdateBus _updateBus;

  Stream<void> get updates => _updateBus.stream;

  Future<List<Receipt>> getAllReceipts() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('receipts', orderBy: 'purchase_ts DESC');
    return maps.map(Receipt.fromMap).toList();
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

    return maps.map(Receipt.fromMap).toList();
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
    await updateAggregates();
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
    await updateAggregates();
  }

  Future<void> deleteReceipt(String id) async {
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('line_items', where: 'receipt_id = ?', whereArgs: [id]);
      await txn.delete('receipts', where: 'id = ?', whereArgs: [id]);
    });
    await updateAggregates();
  }

  Future<List<LineItem>> getLineItemsForReceipt(String receiptId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'line_items',
      where: 'receipt_id = ?',
      whereArgs: [receiptId],
      orderBy: 'rowid ASC',
    );
    return maps.map(LineItem.fromMap).toList();
  }

  Future<void> insertLineItems(List<LineItem> items) async {
    if (items.isEmpty) return;
    final db = await DatabaseHelper.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert('line_items', item.toMap());
    }
    await batch.commit(noResult: true);
    await updateAggregates();
  }

  Stream<List<ReceiptRow>> watchAllReceipts() {
    return _watchList(_fetchAllReceiptRows);
  }

  Stream<List<ReceiptRow>> watchReceiptsByMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    return _watchList(() => _fetchReceiptRowsByMonth(normalized));
  }

  Future<bool> existsByHash(String fileHash) async {
    final db = await DatabaseHelper.database;
    if (fileHash.isEmpty) {
      return false;
    }

    final result = await db.query(
      'receipts',
      columns: ['id'],
      where: 'file_hash = ?',
      whereArgs: [fileHash],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<bool> isDuplicateByHeuristic(Receipt candidate) async {
    final db = await DatabaseHelper.database;
    final merchantId = candidate.merchantId.trim();
    if (merchantId.isEmpty) {
      return false;
    }

    final purchaseTs = candidate.purchaseTimestamp;
    final start =
        purchaseTs.subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    final end = purchaseTs.add(const Duration(days: 1)).millisecondsSinceEpoch;

    final result = await db.rawQuery(
      'SELECT id FROM receipts '
      'WHERE purchase_ts BETWEEN ? AND ? '
      'AND ABS(total_gross - ?) <= 0.05 '
      'AND LOWER(merchant_id) = LOWER(?) '
      'LIMIT 1',
      [start, end, candidate.totalGross, merchantId],
    );

    return result.isNotEmpty;
  }

  Future<String> insertReceiptWithItems({
    required Receipt receipt,
    required List<LineItem> items,
  }) async {
    final db = await DatabaseHelper.database;

    await db.transaction((txn) async {
      await txn.insert('receipts', receipt.toMap());

      if (items.isEmpty) {
        return;
      }

      final batch = txn.batch();
      for (final item in items) {
        final mapped = item.receiptId == receipt.id
            ? item
            : item.copyWith(receiptId: receipt.id);
        batch.insert('line_items', mapped.toMap());
      }
      await batch.commit(noResult: true);
    });

    _updateBus.notifyListeners();
    return receipt.id;
  }

  Future<ReceiptDetails> getReceiptDetails(String receiptId) async {
    final db = await DatabaseHelper.database;
    final receiptResult = await db.rawQuery(
      'SELECT r.*, m.name as merchant_name, m.nip as merchant_nip, '
      'm.address as merchant_address, m.city as merchant_city '
      'FROM receipts r '
      'LEFT JOIN merchants m ON m.id = r.merchant_id '
      'WHERE r.id = ? LIMIT 1',
      [receiptId],
    );

    if (receiptResult.isEmpty) {
      throw StateError('Receipt not found');
    }

    final receiptMap = receiptResult.first;
    final receipt = Receipt.fromMap(receiptMap);
    Merchant? merchant;
    if (receiptMap['merchant_name'] != null) {
      merchant = Merchant(
        id: receiptMap['merchant_id'] as String,
        name: receiptMap['merchant_name'] as String,
        nip: receiptMap['merchant_nip'] as String?,
        address: receiptMap['merchant_address'] as String?,
        city: receiptMap['merchant_city'] as String?,
      );
    }

    final items = await getLineItemsForReceipt(receiptId);

    return ReceiptDetails(
      receipt: receipt,
      merchant: merchant,
      items: items,
    );
  }

  Future<void> updateAggregates() async {
    final db = await DatabaseHelper.database;

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

    _updateBus.notifyListeners();
  }

  Stream<List<T>> _watchList<T>(Future<List<T>> Function() loader) {
    return Stream.multi((controller) async {
      Future<void> emit() async {
        try {
          final data = await loader();
          if (!controller.isClosed) {
            controller.add(data);
          }
        } catch (error, stackTrace) {
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
          }
        }
      }

      await emit();
      final sub = _updateBus.stream.listen((_) => emit());
      controller.onCancel = sub.cancel;
    });
  }

  Future<List<ReceiptRow>> _fetchAllReceiptRows() async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery(
      'SELECT r.*, m.name as merchant_name '
      'FROM receipts r '
      'LEFT JOIN merchants m ON m.id = r.merchant_id '
      'ORDER BY r.purchase_ts DESC',
    );

    return result.map(ReceiptRow.fromMap).toList();
  }

  Future<List<ReceiptRow>> _fetchReceiptRowsByMonth(DateTime month) async {
    final db = await DatabaseHelper.database;
    final start = DateTime(month.year, month.month).millisecondsSinceEpoch;
    final end = DateTime(month.year, month.month + 1).millisecondsSinceEpoch;

    final result = await db.rawQuery(
      'SELECT r.*, m.name as merchant_name '
      'FROM receipts r '
      'LEFT JOIN merchants m ON m.id = r.merchant_id '
      'WHERE r.purchase_ts >= ? AND r.purchase_ts < ? '
      'ORDER BY r.purchase_ts DESC',
      [start, end],
    );

    return result.map(ReceiptRow.fromMap).toList();
  }
}
