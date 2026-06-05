import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/features/month/month_view_model.dart';

void main() {
  test('keeps selected month when it already has positive totals', () {
    final viewModel = MonthViewModel.fromData(
      selectedMonth: DateTime(2025, 8, 20),
      totals: const [
        MonthlyTotal(year: 2025, month: 7, total: 25),
        MonthlyTotal(year: 2025, month: 8, total: 10),
      ],
      overview: null,
    );

    expect(viewModel.normalizedSelectedMonth, DateTime(2025, 8));
    expect(viewModel.replacementSelectedMonth, isNull);
    expect(
      viewModel.dropdownMonths,
      [DateTime(2025, 7), DateTime(2025, 8)],
    );
  });

  test('selects the last positive-total month when selected month has no data',
      () {
    final viewModel = MonthViewModel.fromData(
      selectedMonth: DateTime(2025, 8),
      totals: const [
        MonthlyTotal(year: 2025, month: 6, total: 20),
        MonthlyTotal(year: 2025, month: 7, total: 30),
        MonthlyTotal(year: 2025, month: 8, total: 0),
      ],
      overview: null,
    );

    expect(viewModel.replacementSelectedMonth, DateTime(2025, 7));
    expect(
      viewModel.dropdownMonths,
      [DateTime(2025, 6), DateTime(2025, 7), DateTime(2025, 8)],
    );
  });

  test('uses all returned months for dropdown when no month has positive total',
      () {
    final viewModel = MonthViewModel.fromData(
      selectedMonth: DateTime(2025, 9),
      totals: const [
        MonthlyTotal(year: 2025, month: 7, total: 0),
        MonthlyTotal(year: 2025, month: 8, total: 0),
      ],
      overview: null,
    );

    expect(viewModel.replacementSelectedMonth, isNull);
    expect(
      viewModel.dropdownMonths,
      [DateTime(2025, 7), DateTime(2025, 8), DateTime(2025, 9)],
    );
  });

  test('uses selected month when totals are still loading or empty', () {
    final viewModel = MonthViewModel.fromData(
      selectedMonth: DateTime(2025, 8),
      totals: null,
      overview: null,
    );

    expect(viewModel.replacementSelectedMonth, isNull);
    expect(viewModel.dropdownMonths, [DateTime(2025, 8)]);
  });

  test('maps overview total and receipt count when overview is available', () {
    final viewModel = MonthViewModel.fromData(
      selectedMonth: DateTime(2025, 8),
      totals: const [],
      overview: MonthOverview(
        month: DateTime(2025, 8),
        total: 42.5,
        receiptsCount: 3,
        averageReceipt: 14.16,
        maxReceipt: null,
        topCategories: const [],
      ),
    );

    expect(viewModel.totalAmount, 42.5);
    expect(viewModel.receiptsCount, 3);
  });

  test('maps missing overview to null total and zero receipts', () {
    final viewModel = MonthViewModel.fromData(
      selectedMonth: DateTime(2025, 8),
      totals: const [],
      overview: null,
    );

    expect(viewModel.totalAmount, isNull);
    expect(viewModel.receiptsCount, 0);
  });
}
