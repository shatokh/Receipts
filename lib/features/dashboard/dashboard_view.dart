import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipts/l10n/app_localizations.dart';
import 'package:receipts/l10n/app_localizations_extensions.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/features/dashboard/dashboard_view_model.dart';
import 'package:receipts/features/dashboard/widgets/dashboard_states.dart';
import 'package:receipts/features/dashboard/widgets/kpi_cards.dart';
import 'package:receipts/features/dashboard/widgets/month_dropdown.dart';
import 'package:receipts/features/dashboard/widgets/monthly_chart.dart';
import 'package:receipts/features/dashboard/widgets/quick_insights.dart';
import 'package:receipts/features/dashboard/widgets/top_categories_section.dart';
import 'package:receipts/theme.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthlyTotalsAsync = ref.watch(monthlyTotalsProvider);
    final monthOverviewAsync = ref.watch(monthOverviewProvider(selectedMonth));
    final kpisAsync = ref.watch(dashboardKpisProvider);
    monthlyTotalsAsync.whenData((totals) {
      final viewModel = DashboardViewModel.fromMonthlyTotals(
        totals: totals,
        selectedMonth: selectedMonth,
      );
      final replacementSelectedMonth = viewModel.replacementSelectedMonth;
      if (replacementSelectedMonth != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }

          final currentSelectedMonth = ref.read(selectedMonthProvider);
          if (currentSelectedMonth != replacementSelectedMonth) {
            ref.read(selectedMonthProvider.notifier).state =
                replacementSelectedMonth;
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t.dashboardTitle),
        actions: [
          IconButton(
            key: const ValueKey('nav_import_action'),
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/import'),
            tooltip: t.importPdf,
          ),
        ],
      ),
      body: monthlyTotalsAsync.when(
        data: (totals) {
          final viewModel = DashboardViewModel.fromMonthlyTotals(
            totals: totals,
            selectedMonth: selectedMonth,
          );

          if (!viewModel.hasMonthlyTotals) {
            return DashboardEmptyState(
              onImport: () => context.go('/import'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardKpiCards(kpis: kpisAsync),
                const SizedBox(height: AppSpacing.lg),
                MonthlyChart(totals: totals),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.selectedMonthLabel,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    MonthDropdown(
                      months: viewModel.dropdownMonths,
                      selectedMonth: viewModel.normalizedSelectedMonth,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.divider.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    t.onDeviceProcessing,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  t.spendingByCategoryForMonth(
                    t.formatMonthYear(selectedMonth),
                  ),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TopCategoriesSection(overview: monthOverviewAsync),
                const SizedBox(height: AppSpacing.lg),
                QuickInsights(
                  overview: monthOverviewAsync,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => DashboardErrorState(error: error),
      ),
    );
  }
}
