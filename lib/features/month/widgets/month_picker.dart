import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipts/app/app_test_keys.dart';
import 'package:receipts/l10n/app_localizations.dart';
import 'package:receipts/l10n/app_localizations_extensions.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/theme.dart';

class MonthPicker extends ConsumerWidget {
  const MonthPicker({
    super.key,
    required this.months,
    required this.selectedMonth,
  });

  final List<DateTime> months;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final value = months.firstWhere(
      (month) =>
          month.year == selectedMonth.year &&
          month.month == selectedMonth.month,
      orElse: () => selectedMonth,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Semantics(
        container: true,
        identifier: AppTestSemanticsIds.monthPicker,
        child: DropdownButton<DateTime>(
          value: value,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          items: months
              .asMap()
              .entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.value,
                  child: Semantics(
                    container: true,
                    identifier: switch (entry.key) {
                      0 => AppTestSemanticsIds.monthOption0,
                      1 => AppTestSemanticsIds.monthOption1,
                      _ => null,
                    },
                    child: Text(t.formatMonthYear(entry.value)),
                  ),
                ),
              )
              .toList(),
          onChanged: (month) {
            if (month != null) {
              ref.read(selectedMonthProvider.notifier).state = month;
            }
          },
        ),
      ),
    );
  }
}
