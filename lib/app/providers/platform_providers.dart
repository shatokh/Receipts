import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/features/import/file_import_service.dart';
import 'package:receipts/platform/pdf_text_extractor/android_pdf_text_extractor.dart';
import 'package:receipts/platform/pdf_text_extractor/pdf_text_extractor.dart';
import 'package:receipts/platform/receipt_source_opener/android_receipt_source_opener.dart';
import 'package:receipts/platform/receipt_source_opener/receipt_source_opener.dart';

final pdfTextExtractorProvider = Provider<PdfTextExtractor>((ref) {
  return AndroidPdfTextExtractor();
});

final fileImportServiceProvider = Provider<FileImportService>((ref) {
  return const FilePickerFileImportService();
});

final receiptSourceOpenerProvider = Provider<ReceiptSourceOpener>((ref) {
  return AndroidReceiptSourceOpener();
});
