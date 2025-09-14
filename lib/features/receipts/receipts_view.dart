import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:biedronka_expenses/theme.dart';
import 'package:biedronka_expenses/data/demo_data.dart';

class ReceiptsView extends ConsumerStatefulWidget {
  const ReceiptsView({super.key});

  @override
  ConsumerState<ReceiptsView> createState() => _ReceiptsViewState();
}

class _ReceiptsViewState extends ConsumerState<ReceiptsView> {
  String _searchQuery = '';
  DateTime? _selectedMonth;
  RangeValues _totalRange = const RangeValues(0, 500);

  @override
  Widget build(BuildContext context) {
    final receipts = DemoData.getAugust2025Receipts();
    final filteredReceipts = _filterReceipts(receipts);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
      ),
      body: Column(
        children: [
          _SearchAndFilters(),
          Expanded(
            child: filteredReceipts.isEmpty
                ? _EmptyState()
                : _ReceiptsList(receipts: filteredReceipts),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterReceipts(List<dynamic> receipts) {
    return receipts.where((receipt) {
      final matchesSearch = _searchQuery.isEmpty ||
          'biedronka'.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          DateFormat('yyyy-MM-dd').format(receipt.purchaseTimestamp).contains(_searchQuery);
      
      final matchesMonth = _selectedMonth == null ||
          (receipt.purchaseTimestamp.year == _selectedMonth!.year &&
           receipt.purchaseTimestamp.month == _selectedMonth!.month);
      
      final matchesTotal = receipt.totalGross >= _totalRange.start &&
          receipt.totalGross <= _totalRange.end;
      
      return matchesSearch && matchesMonth && matchesTotal;
    }).toList();
  }

  Widget _SearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by merchant or date',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<DateTime?>(
                  initialValue: _selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All months'),
                    ),
                    DropdownMenuItem(
                      value: DateTime(2025, 8),
                      child: Text(DateFormat('MMMM yyyy').format(DateTime(2025, 8))),
                    ),
                    DropdownMenuItem(
                      value: DateTime(2025, 7),
                      child: Text(DateFormat('MMMM yyyy').format(DateTime(2025, 7))),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total range: PLN ${_totalRange.start.round()} - ${_totalRange.end.round()}',
                      style: AppTextStyles.labelSmall,
                    ),
                    RangeSlider(
                      values: _totalRange,
                      min: 0,
                      max: 500,
                      divisions: 10,
                      onChanged: (values) {
                        setState(() {
                          _totalRange = values;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _EmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No receipts found',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try adjusting your search or filters',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptsList extends StatelessWidget {
  final List<dynamic> receipts;

  const _ReceiptsList({required this.receipts});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'PLN ', decimalDigits: 2);
    
    return ListView.builder(
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.receipt,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              'Biedronka',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              dateFormat.format(receipt.purchaseTimestamp),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currencyFormat.format(receipt.totalGross),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            onTap: () => context.go('/receipt/${receipt.id}'),
          ),
        );
      },
    );
  }
}