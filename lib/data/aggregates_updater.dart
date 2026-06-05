import 'package:receipts/data/month_date_range.dart';
import 'package:receipts/domain/category_definitions.dart';
import 'package:sqflite/sqflite.dart';

class AggregatesUpdater {
  const AggregatesUpdater();

  Future<void> rebuildAll(Database db) async {
    try {
      await db.transaction((txn) async {
        await _rebuildMonthlyTotals(txn);
        await _rebuildCategoryTotals(txn);
      });
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateForMonths(Database db, Iterable<DateTime> months) async {
    final monthStarts = _normalizeMonths(months);
    if (monthStarts.isEmpty) {
      return;
    }

    try {
      for (final monthStart in monthStarts) {
        await _updateForMonth(db, monthStart);
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> _rebuildMonthlyTotals(Transaction txn) async {
    await txn.execute('DELETE FROM monthly_totals');
    await txn.execute('''
      INSERT INTO monthly_totals (year, month, total)
      SELECT
        CAST(strftime('%Y', purchase_ts/1000, 'unixepoch') AS INTEGER) as year,
        CAST(strftime('%m', purchase_ts/1000, 'unixepoch') AS INTEGER) as month,
        SUM(total_gross) as total
      FROM receipts
      GROUP BY year, month
    ''');
  }

  Future<void> _rebuildCategoryTotals(Transaction txn) async {
    await txn.execute('DELETE FROM category_month_totals');

    final rows = await txn.rawQuery('''
      SELECT
        li.category_id as category_id,
        CAST(strftime('%Y', r.purchase_ts/1000, 'unixepoch') AS INTEGER) as year,
        CAST(strftime('%m', r.purchase_ts/1000, 'unixepoch') AS INTEGER) as month,
        SUM(li.total) as total
      FROM line_items li
      JOIN receipts r ON li.receipt_id = r.id
      GROUP BY li.category_id, year, month
    ''');

    final totals = <String, _CategoryMonthTotal>{};
    for (final row in rows) {
      final categoryId = normalizeCategoryId(row['category_id'] as String?);
      final year = row['year'] as int;
      final month = row['month'] as int;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      final key = '$categoryId-$year-$month';
      final current = totals[key];
      totals[key] = _CategoryMonthTotal(
        categoryId: categoryId,
        year: year,
        month: month,
        total: (current?.total ?? 0.0) + total,
      );
    }

    for (final total in totals.values) {
      await txn.insert('category_month_totals', {
        'category_id': total.categoryId,
        'year': total.year,
        'month': total.month,
        'total': total.total,
      });
    }
  }

  Future<void> _updateForMonth(Database db, DateTime monthStart) async {
    final monthRange = MonthDateRange.forDate(monthStart);
    final month = monthRange.start;
    final start = monthRange.startMs;
    final end = monthRange.endMs;

    await db.transaction((txn) async {
      final totalResult = await txn.rawQuery(
        'SELECT SUM(total_gross) as total FROM receipts WHERE purchase_ts >= ? AND purchase_ts < ?',
        [start, end],
      );
      final totalAmount =
          (totalResult.isNotEmpty ? totalResult.first['total'] : null) as num?;

      final totalValue = (totalAmount ?? 0).toDouble();

      await txn.rawInsert(
        'INSERT INTO monthly_totals (year, month, total) VALUES (?, ?, ?) '
        'ON CONFLICT(year, month) DO UPDATE SET total = excluded.total',
        [month.year, month.month, totalValue],
      );

      await txn.delete(
        'category_month_totals',
        where: 'year = ? AND month = ?',
        whereArgs: [month.year, month.month],
      );

      final categoryRows = await txn.rawQuery(
        'SELECT li.category_id as category_id, SUM(li.total) as total '
        'FROM line_items li '
        'JOIN receipts r ON r.id = li.receipt_id '
        'WHERE r.purchase_ts >= ? AND r.purchase_ts < ? '
        'GROUP BY li.category_id',
        [start, end],
      );

      final totalsByCategory = <String, double>{};
      for (final row in categoryRows) {
        final rawCategoryId = row['category_id'] as String?;
        final amount = (row['total'] as num?)?.toDouble() ?? 0.0;
        final categoryId = normalizeCategoryId(rawCategoryId);
        totalsByCategory.update(
          categoryId,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }

      for (final entry in totalsByCategory.entries) {
        await txn.rawInsert(
          'INSERT INTO category_month_totals (category_id, year, month, total) '
          'VALUES (?, ?, ?, ?) '
          'ON CONFLICT(category_id, year, month) DO UPDATE SET total = excluded.total',
          [entry.key, month.year, month.month, entry.value],
        );
      }

      if (categoryRows.isEmpty) {
        // ensure table does not hold stale zero rows for this month
        await txn.delete(
          'category_month_totals',
          where: 'year = ? AND month = ? AND total = 0',
          whereArgs: [month.year, month.month],
        );
      }
    });
  }

  List<DateTime> _normalizeMonths(Iterable<DateTime> months) {
    final normalized = <String, DateTime>{};
    for (final month in months) {
      final monthStart = DateTime(month.year, month.month);
      normalized['${monthStart.year}-${monthStart.month}'] = monthStart;
    }
    final result = normalized.values.toList()..sort();
    return result;
  }
}

class _CategoryMonthTotal {
  const _CategoryMonthTotal({
    required this.categoryId,
    required this.year,
    required this.month,
    required this.total,
  });

  final String categoryId;
  final int year;
  final int month;
  final double total;
}
