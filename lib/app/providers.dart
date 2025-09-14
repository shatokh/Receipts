import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biedronka_expenses/data/repositories/receipt_repository.dart';
import 'package:biedronka_expenses/data/repositories/category_repository.dart';
import 'package:biedronka_expenses/domain/services/receipt_parser.dart';
import 'package:biedronka_expenses/platform/pdf_text_extractor/android_pdf_text_extractor.dart';
import 'package:biedronka_expenses/domain/models/receipt.dart';
import 'package:biedronka_expenses/domain/models/line_item.dart';
import 'package:biedronka_expenses/domain/models/monthly_total.dart';
import 'package:biedronka_expenses/domain/models/category.dart';

// Repository providers
final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

// Service providers
final pdfTextExtractorProvider = Provider((ref) {
  return AndroidPdfTextExtractor();
});

final receiptParserProvider = Provider<ReceiptParser>((ref) {
  return ReceiptParser(ref.watch(categoryRepositoryProvider));
});

// Data providers
final receiptsProvider = FutureProvider<List<Receipt>>((ref) async {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getAllReceipts();
});

final monthlyTotalsProvider = FutureProvider<List<MonthlyTotal>>((ref) async {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getMonthlyTotals(12);
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getAllCategories();
});

// Current month provider
final currentMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime(2025, 8); // Default to August 2025 per requirements
});

// Receipts for current month
final receiptsForMonthProvider = FutureProvider<List<Receipt>>((ref) async {
  final currentMonth = ref.watch(currentMonthProvider);
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getReceiptsByMonth(currentMonth.year, currentMonth.month);
});

// Top categories for current month
final topCategoriesForMonthProvider = FutureProvider<List<CategoryMonthTotal>>((ref) async {
  final currentMonth = ref.watch(currentMonthProvider);
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getTopCategoriesForMonth(currentMonth.year, currentMonth.month, limit: 5);
});

// Total for current month
final totalForMonthProvider = FutureProvider<double>((ref) async {
  final currentMonth = ref.watch(currentMonthProvider);
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getTotalForMonth(currentMonth.year, currentMonth.month);
});

// Receipt count for current month
final receiptCountForMonthProvider = FutureProvider<int>((ref) async {
  final currentMonth = ref.watch(currentMonthProvider);
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getReceiptCountForMonth(currentMonth.year, currentMonth.month);
});

// Max receipt for current month
final maxReceiptForMonthProvider = FutureProvider<Receipt?>((ref) async {
  final currentMonth = ref.watch(currentMonthProvider);
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getMaxReceiptForMonth(currentMonth.year, currentMonth.month);
});

// Individual receipt with line items
final receiptWithItemsProvider = FutureProvider.family<({Receipt? receipt, List<LineItem> items}), String>((ref, receiptId) async {
  final repository = ref.watch(receiptRepositoryProvider);
  final receipt = await repository.getReceipt(receiptId);
  final items = receipt != null ? await repository.getLineItemsForReceipt(receiptId) : <LineItem>[];
  
  return (receipt: receipt, items: items);
});

// Settings providers
final sentryEnabledProvider = StateProvider<bool>((ref) => false);

// Import state provider
final importStatusProvider = StateProvider<String?>((ref) => null);