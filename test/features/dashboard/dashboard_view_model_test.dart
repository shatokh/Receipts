import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/features/dashboard/dashboard_view_model.dart';

void main() {
  test('keeps selected month when it already has positive totals', () {
    final viewModel = DashboardViewModel.fromMonthlyTotals(
      selectedMonth: DateTime(2025, 8, 20),
      totals: const [
        MonthlyTotal(year: 2025, month: 7, total: 25),
        MonthlyTotal(year: 2025, month: 8, total: 10),
      ],
    );

    expect(viewModel.hasMonthlyTotals, isTrue);
    expect(viewModel.normalizedSelectedMonth, DateTime(2025, 8));
    expect(viewModel.replacementSelectedMonth, isNull);
    expect(
      viewModel.dropdownMonths,
      [DateTime(2025, 7), DateTime(2025, 8)],
    );
  });

  test('selects the last positive-total month when selected month has no data',
      () {
    final viewModel = DashboardViewModel.fromMonthlyTotals(
      selectedMonth: DateTime(2025, 8),
      totals: const [
        MonthlyTotal(year: 2025, month: 6, total: 20),
        MonthlyTotal(year: 2025, month: 7, total: 30),
        MonthlyTotal(year: 2025, month: 8, total: 0),
      ],
    );

    expect(viewModel.replacementSelectedMonth, DateTime(2025, 7));
    expect(
      viewModel.dropdownMonths,
      [DateTime(2025, 6), DateTime(2025, 7), DateTime(2025, 8)],
    );
  });

  test('uses all returned months for dropdown when no month has positive total',
      () {
    final viewModel = DashboardViewModel.fromMonthlyTotals(
      selectedMonth: DateTime(2025, 9),
      totals: const [
        MonthlyTotal(year: 2025, month: 7, total: 0),
        MonthlyTotal(year: 2025, month: 8, total: 0),
      ],
    );

    expect(viewModel.replacementSelectedMonth, isNull);
    expect(
      viewModel.dropdownMonths,
      [DateTime(2025, 7), DateTime(2025, 8), DateTime(2025, 9)],
    );
  });

  test('marks empty totals and still exposes selected month for dropdown', () {
    final viewModel = DashboardViewModel.fromMonthlyTotals(
      selectedMonth: DateTime(2025, 8),
      totals: const [],
    );

    expect(viewModel.hasMonthlyTotals, isFalse);
    expect(viewModel.replacementSelectedMonth, isNull);
    expect(viewModel.dropdownMonths, [DateTime(2025, 8)]);
  });
}
