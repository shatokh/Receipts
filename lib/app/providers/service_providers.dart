import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/app/providers/platform_providers.dart';
import 'package:receipts/app/providers/repository_providers.dart';
import 'package:receipts/app/providers/settings_providers.dart';
import 'package:receipts/domain/parsing/receipt_parser.dart';
import 'package:receipts/features/import/import_service.dart';

final receiptParserProvider = Provider<ReceiptParser>((ref) {
  return ReceiptParser();
});

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(
    pdf: ref.read(pdfTextExtractorProvider),
    parser: ref.read(receiptParserProvider),
    receipts: ref.read(receiptRepositoryProvider),
    analytics: ref.read(analyticsRepositoryProvider),
    errorLogger: ref.watch(errorLogServiceProvider),
  );
});
