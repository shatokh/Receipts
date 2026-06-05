import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipts/l10n/app_localizations.dart';
import 'package:receipts/l10n/app_localizations_extensions.dart';

import 'package:receipts/app/providers.dart';

class MonthDropdown extends ConsumerWidget {
  const MonthDropdown({
    super.key,
    required this.months,
    required this.selectedMonth,
  });

  final List<DateTime> months;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final normalizedSelected =
        DateTime(selectedMonth.year, selectedMonth.month);

    final value = months.firstWhere(
      (month) =>
          month.year == normalizedSelected.year &&
          month.month == normalizedSelected.month,
      orElse: () => normalizedSelected,
    );

    return DropdownButton<DateTime>(
      value: value,
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
    );
  }
}
