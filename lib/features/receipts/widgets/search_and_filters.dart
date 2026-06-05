import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipts/l10n/app_localizations.dart';
import 'package:receipts/l10n/app_localizations_extensions.dart';

import 'package:receipts/theme.dart';

class SearchAndFilters extends ConsumerStatefulWidget {
  const SearchAndFilters({
    super.key,
    required this.searchQuery,
    required this.selectedMonth,
    required this.amountRange,
    required this.monthOptions,
    required this.onSearchChanged,
    required this.onMonthChanged,
    required this.onAmountChanged,
  });

  final String searchQuery;
  final DateTime? selectedMonth;
  final RangeValues amountRange;
  final List<DateTime> monthOptions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DateTime?> onMonthChanged;
  final ValueChanged<RangeValues> onAmountChanged;

  @override
  ConsumerState<SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends ConsumerState<SearchAndFilters> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant SearchAndFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: t.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: widget.onSearchChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              Widget buildMonthDropdown({bool expandWidth = false}) {
                final dropdown = DropdownButtonFormField<DateTime?>(
                  initialValue: widget.selectedMonth,
                  decoration: InputDecoration(
                    labelText: t.monthFilterLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(t.allMonths),
                    ),
                    ...widget.monthOptions.map(
                      (month) => DropdownMenuItem(
                        value: month,
                        child: Text(t.formatMonthYear(month)),
                      ),
                    ),
                  ],
                  onChanged: widget.onMonthChanged,
                );

                if (expandWidth) {
                  return SizedBox(width: double.infinity, child: dropdown);
                }

                return dropdown;
              }

              Widget buildAmountFilter() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.totalRangeLabel(
                        widget.amountRange.start.round(),
                        widget.amountRange.end.round(),
                      ),
                      style: AppTextStyles.labelSmall,
                    ),
                    RangeSlider(
                      values: widget.amountRange,
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      onChanged: widget.onAmountChanged,
                    ),
                  ],
                );
              }

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildMonthDropdown(expandWidth: true),
                    const SizedBox(height: AppSpacing.md),
                    buildAmountFilter(),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: buildMonthDropdown()),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: buildAmountFilter()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
