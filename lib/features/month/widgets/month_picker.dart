import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      child: DropdownButton<DateTime>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: months
            .map(
              (month) => DropdownMenuItem(
                value: month,
                child: Text(t.formatMonthYear(month)),
              ),
            )
            .toList(),
        onChanged: (month) {
          if (month != null) {
            ref.read(selectedMonthProvider.notifier).state = month;
          }
        },
      ),
    );
  }
}
