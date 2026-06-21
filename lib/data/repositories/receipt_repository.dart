import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:receipts/data/aggregates_updater.dart';
import 'package:receipts/data/database.dart';
import 'package:receipts/data/database_update_bus.dart';
import 'package:receipts/data/database_update_bus_provider.dart';
import 'package:receipts/data/database_watch.dart';
import 'package:receipts/data/month_date_range.dart';
import 'package:receipts/domain/models/line_item.dart';
import 'package:receipts/domain/models/merchant.dart';
import 'package:receipts/domain/models/receipt.dart';
import 'package:receipts/domain/models/receipt_details.dart';
import 'package:receipts/domain/models/receipt_row.dart';
import 'package:receipts/domain/value_objects/receipt_month.dart';

typedef Reader = T Function<T>(ProviderListenable<T> provider);

class ReceiptRepository {
  ReceiptRepository(Reader read) : _updateBus = read(databaseUpdateBusProvider);

  final DatabaseUpdateBus _updateBus;
  final AggregatesUpdater _aggregatesUpdater = const AggregatesUpdater();

  Stream<void> get updates => _updateBus.stream;

  Future<List<Receipt>> getAllReceipts() async {
    final db = await DatabaseHelper.database;
    try {
      final maps = await db.query('receipts', orderBy: 'purchase_ts DESC');
      return maps.map(Receipt.fromMap).toList();
    } catch (error) {
      rethrow;
    }
  }

  Future<List<Receipt>> getReceiptsByMonth(int year, int month) async {
    final db = await DatabaseHelper.database;
    final monthRange = MonthDateRange.forYearMonth(year, month);
    try {
      final maps = await db.query(
        'receipts',
        where: 'purchase_ts >= ? AND purchase_ts < ?',
        whereArgs: [monthRange.startMs, monthRange.endMs],
        orderBy: 'purchase_ts DESC',
      );

      return maps.map(Receipt.fromMap).toList();
    } catch (error) {
      rethrow;
    }
  }

  Future<Receipt?> getReceipt(String id) async {
    final db = await DatabaseHelper.database;
    try {
      final maps = await db.query('receipts', where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) return null;
      return Receipt.fromMap(maps.first);
    } catch (error) {
      rethrow;
    }
  }

  Future<String> insertReceipt(Receipt receipt) async {
    final db = await DatabaseHelper.database;
    try {
      await db.insert('receipts', receipt.toMap());
    } catch (error) {
      rethrow;
    }
    await _updateAggregatesForMonths([receipt.purchaseTimestamp]);
    return receipt.id;
  }

  Future<void> updateReceipt(Receipt receipt) async {
    final db = await DatabaseHelper.database;
    DateTime? previousMonth;
    try {
      previousMonth = await _fetchReceiptMonth(db, receipt.id);
      await db.update(
        'receipts',
        receipt.toMap(),
        where: 'id = ?',
        whereArgs: [receipt.id],
      );
    } catch (error) {
      rethrow;
    }
    await _updateAggregatesForMonths(
      [
        receipt.purchaseTimestamp,
        if (previousMonth != null) previousMonth,
      ],
    );
  }

  Future<void> deleteReceipt(String id) async {
    final db = await DatabaseHelper.database;
    DateTime? deletedMonth;
    try {
      await db.transaction((txn) async {
        deletedMonth = await _fetchReceiptMonth(txn, id);
        await txn.delete(
          'line_items',
          where: 'receipt_id = ?',
          whereArgs: [id],
        );
        await txn.delete('receipts', where: 'id = ?', whereArgs: [id]);
      });
    } catch (error) {
      rethrow;
    }
    await _updateAggregatesForMonths(
      deletedMonth != null ? [deletedMonth!] : const [],
    );
  }

  Future<List<LineItem>> getLineItemsForReceipt(String receiptId) async {
    final db = await DatabaseHelper.database;
    try {
      final maps = await db.query(
        'line_items',
        where: 'receipt_id = ?',
        whereArgs: [receiptId],
        orderBy: 'rowid ASC',
      );
      return maps.map(LineItem.fromMap).toList();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> insertLineItems(List<LineItem> items) async {
    if (items.isEmpty) return;
    final db = await DatabaseHelper.database;
    try {
      final batch = db.batch();
      for (final item in items) {
        batch.insert('line_items', item.toMap());
      }
      await batch.commit(noResult: true);
    } catch (error) {
      rethrow;
    }
    final months = await _fetchReceiptMonths(db, items);
    await _updateAggregatesForMonths(months);
  }

  Stream<List<ReceiptRow>> watchAllReceipts() {
    return watchDatabase(
      updateBus: _updateBus,
      loader: _fetchAllReceiptRows,
    );
  }

  Stream<List<ReceiptRow>> watchReceiptsByMonth(DateTime month) {
    final normalized = ReceiptMonth.fromDate(month).start;
    return watchDatabase(
      updateBus: _updateBus,
      loader: () => _fetchReceiptRowsByMonth(normalized),
    );
  }

  Future<bool> existsByHash(String fileHash) async {
    final db = await DatabaseHelper.database;
    if (fileHash.isEmpty) {
      return false;
    }

    try {
      final result = await db.query(
        'receipts',
        columns: ['id'],
        where: 'file_hash = ?',
        whereArgs: [fileHash],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (error) {
      rethrow;
    }
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

    try {
      final result = await db.rawQuery(
        'SELECT id FROM receipts '
        'WHERE purchase_ts BETWEEN ? AND ? '
        'AND ABS(total_gross - ?) <= 0.05 '
        'AND LOWER(merchant_id) = LOWER(?) '
        'LIMIT 1',
        [start, end, candidate.totalGross, merchantId],
      );

      return result.isNotEmpty;
    } catch (error) {
      rethrow;
    }
  }

  Future<String> insertReceiptWithItems({
    required Receipt receipt,
    required List<LineItem> items,
  }) async {
    final db = await DatabaseHelper.database;

    try {
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
    } catch (error) {
      rethrow;
    }

    await _updateAggregatesForMonths([receipt.purchaseTimestamp]);
    return receipt.id;
  }

  Future<ReceiptDetails> getReceiptDetails(String receiptId) async {
    final db = await DatabaseHelper.database;
    try {
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
    } catch (error) {
      rethrow;
    }
  }

  Future<void> _updateAggregatesForMonths(Iterable<DateTime> months) async {
    if (months.isNotEmpty) {
      final db = await DatabaseHelper.database;
      try {
        await _aggregatesUpdater.updateForMonths(db, months);
      } catch (error) {
        rethrow;
      }
    }

    _updateBus.notifyListeners();
  }

  Future<List<ReceiptRow>> _fetchAllReceiptRows() async {
    final db = await DatabaseHelper.database;
    try {
      final result = await db.rawQuery(
        'SELECT r.*, m.name as merchant_name '
        'FROM receipts r '
        'LEFT JOIN merchants m ON m.id = r.merchant_id '
        'ORDER BY r.purchase_ts DESC',
      );

      return result.map(ReceiptRow.fromMap).toList();
    } catch (error) {
      rethrow;
    }
  }

  Future<List<ReceiptRow>> _fetchReceiptRowsByMonth(DateTime month) async {
    final db = await DatabaseHelper.database;
    final monthRange = MonthDateRange.forDate(month);

    try {
      final result = await db.rawQuery(
        'SELECT r.*, m.name as merchant_name '
        'FROM receipts r '
        'LEFT JOIN merchants m ON m.id = r.merchant_id '
        'WHERE r.purchase_ts >= ? AND r.purchase_ts < ? '
        'ORDER BY r.purchase_ts DESC',
        [monthRange.startMs, monthRange.endMs],
      );

      return result.map(ReceiptRow.fromMap).toList();
    } catch (error) {
      rethrow;
    }
  }

  Future<DateTime?> _fetchReceiptMonth(
    DatabaseExecutor db,
    String receiptId,
  ) async {
    try {
      final result = await db.query(
        'receipts',
        columns: ['purchase_ts'],
        where: 'id = ?',
        whereArgs: [receiptId],
        limit: 1,
      );
      if (result.isEmpty) {
        return null;
      }
      final timestamp = result.first['purchase_ts'] as int?;
      if (timestamp == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (error) {
      rethrow;
    }
  }

  Future<Set<DateTime>> _fetchReceiptMonths(
    Database db,
    List<LineItem> items,
  ) async {
    final receiptIds = items.map((item) => item.receiptId).toSet();
    if (receiptIds.isEmpty) {
      return {};
    }
    final placeholders = List.filled(receiptIds.length, '?').join(', ');
    try {
      final result = await db.rawQuery(
        'SELECT DISTINCT purchase_ts FROM receipts WHERE id IN ($placeholders)',
        receiptIds.toList(),
      );
      final months = <DateTime>{};
      for (final row in result) {
        final timestamp = row['purchase_ts'] as int?;
        if (timestamp == null) {
          continue;
        }
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        months.add(ReceiptMonth.fromDate(date).start);
      }
      return months;
    } catch (error) {
      rethrow;
    }
  }
}
