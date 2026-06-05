import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/data/repositories/analytics_repository.dart';
import 'package:receipts/data/repositories/category_repository.dart';
import 'package:receipts/data/repositories/receipt_repository.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  final repository = ReceiptRepository(ref.read);
  return repository;
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final repository = AnalyticsRepository(ref.read);
  return repository;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});
