import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/core/privacy/sanitizer.dart';
import 'package:receipts/data/aggregates_updater.dart';
import 'package:receipts/data/database.dart';
import 'package:receipts/data/database_update_bus.dart';
import 'package:receipts/data/database_update_bus_provider.dart';
import 'package:receipts/data/database_watch.dart';
import 'package:receipts/data/month_date_range.dart';
import 'package:receipts/domain/category_definitions.dart';
import 'package:receipts/domain/models/dashboard_kpis.dart';
import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/domain/models/receipt_row.dart';

typedef Reader = T Function<T>(ProviderListenable<T> provider);

class AnalyticsRepository {
  AnalyticsRepository(Reader read)
      : _updateBus = read(databaseUpdateBusProvider);

  final DatabaseUpdateBus _updateBus;
  final AggregatesUpdater _aggregatesUpdater = const AggregatesUpdater();

  Stream<void> get updates => _updateBus.stream;

  void recordImportTelemetry({
    required String sourceUri,
    required String stage,
    Map<String, dynamic> details = const {},
  }) {
    final safeDetails = PrivacySanitizer.sanitizeDetails(details);
    final payload = <String, dynamic>{
      'source': PrivacySanitizer.sourceMarker(sourceUri),
      'stage': stage,
      if (safeDetails.isNotEmpty) 'details': safeDetails,
    };

    developer.log(
      'import_telemetry',
      name: 'ImportTelemetry',
      error: jsonEncode(payload),
    );
  }

  Stream<List<MonthlyTotal>> watchLast12MonthsTotals() {
    return watchDatabase(
      updateBus: _updateBus,
      loader: _fetchLast12MonthsTotals,
    );
  }

  Future<void> updateAggregatesForMonth(DateTime monthStart) async {
    final db = await DatabaseHelper.database;
    try {
      await _aggregatesUpdater.updateForMonths(db, [monthStart]);
    } catch (error) {
      rethrow;
    }

    _updateBus.notifyListeners();
  }

  Future<MonthOverview> getMonthOverview(DateTime month) async {
    final db = await DatabaseHelper.database;
    final monthRange = MonthDateRange.forDate(month);
    final normalized = monthRange.start;
    final startOfMonth = monthRange.startMs;
    final startOfNextMonth = monthRange.endMs;

    try {
      final totalsResult = await db.rawQuery(
        'SELECT COUNT(*) as count, SUM(total_gross) as total FROM receipts WHERE purchase_ts >= ? AND purchase_ts < ?',
        [startOfMonth, startOfNextMonth],
      );

      final totalsRow =
          totalsResult.isNotEmpty ? totalsResult.first : <String, Object?>{};
      final receiptsCount = (totalsRow['count'] as int?) ??
          (totalsRow['count'] as num?)?.toInt() ??
          0;
      final totalAmount = (totalsRow['total'] as num?)?.toDouble() ?? 0.0;
      final averageReceipt =
          receiptsCount > 0 ? totalAmount / receiptsCount : 0.0;

      final maxReceiptResult = await db.rawQuery(
        'SELECT r.*, m.name as merchant_name FROM receipts r '
        'LEFT JOIN merchants m ON m.id = r.merchant_id '
        'WHERE r.purchase_ts >= ? AND r.purchase_ts < ? '
        'ORDER BY r.total_gross DESC LIMIT 1',
        [startOfMonth, startOfNextMonth],
      );

      final ReceiptRow? maxReceipt = maxReceiptResult.isNotEmpty
          ? ReceiptRow.fromMap(maxReceiptResult.first)
          : null;

      final categoriesResult = await db.rawQuery(
        'SELECT li.category_id as category_id, SUM(li.total) as total '
        'FROM line_items li '
        'JOIN receipts r ON r.id = li.receipt_id '
        'WHERE r.purchase_ts >= ? AND r.purchase_ts < ? '
        'GROUP BY li.category_id',
        [startOfMonth, startOfNextMonth],
      );

      final totalsByCategory = <String, double>{
        for (final definition in categoryDefinitions) definition.id: 0.0,
      };

      for (final row in categoriesResult) {
        final rawCategoryId = row['category_id'] as String?;
        final amount = (row['total'] as num?)?.toDouble() ?? 0.0;
        final categoryId = normalizeCategoryId(rawCategoryId);
        totalsByCategory.update(
          categoryId,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }

      final topCategories = [
        for (final definition in categoryDefinitions)
          CategoryBreakdown(
            categoryId: definition.id,
            amount: totalsByCategory[definition.id] ?? 0.0,
          ),
      ];

      return MonthOverview(
        month: normalized,
        total: totalAmount,
        receiptsCount: receiptsCount,
        averageReceipt: averageReceipt,
        maxReceipt: maxReceipt,
        topCategories: topCategories,
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<DashboardKpis> getLast30DaysKpi() async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count, SUM(total_gross) as total FROM receipts WHERE purchase_ts >= ?',
        [thirtyDaysAgo.millisecondsSinceEpoch],
      );

      final row = result.isNotEmpty ? result.first : <String, Object?>{};
      final count =
          (row['count'] as int?) ?? (row['count'] as num?)?.toInt() ?? 0;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      final average = count > 0 ? total / count : 0.0;

      return DashboardKpis(
        totalLast30Days: total,
        averageReceipt: average,
        receiptsCount: count,
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<List<MonthlyTotal>> _fetchLast12MonthsTotals() async {
    final db = await DatabaseHelper.database;
    try {
      final maps = await db.query(
        'monthly_totals',
        orderBy: 'year DESC, month DESC',
        limit: 12,
      );

      if (maps.isEmpty) {
        return [];
      }

      final totalsDesc = maps.map(MonthlyTotal.fromMap).toList();
      final latest = totalsDesc.first;
      final latestDate = DateTime(latest.year, latest.month);
      final earliest = totalsDesc.last;
      final earliestDate = DateTime(earliest.year, earliest.month);
      final span = (latestDate.year - earliestDate.year) * 12 +
          latestDate.month -
          earliestDate.month +
          1;
      final monthsToInclude = max(1, min(12, span));
      final startDate =
          DateTime(latestDate.year, latestDate.month - (monthsToInclude - 1));

      final totalsMap = <String, double>{
        for (final total in totalsDesc)
          _monthKey(total.year, total.month): total.total,
      };

      final result = <MonthlyTotal>[];
      for (int i = 0; i < monthsToInclude; i++) {
        final date = DateTime(startDate.year, startDate.month + i);
        final key = _monthKey(date.year, date.month);
        final amount = totalsMap[key] ?? 0.0;
        result.add(
          MonthlyTotal(
            year: date.year,
            month: date.month,
            total: amount,
          ),
        );
      }

      return result;
    } catch (error) {
      rethrow;
    }
  }

  String _monthKey(int year, int month) =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
}
