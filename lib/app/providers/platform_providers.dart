import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/features/import/file_import_service.dart';
import 'package:receipts/platform/pdf_text_extractor/android_pdf_text_extractor.dart';
import 'package:receipts/platform/pdf_text_extractor/pdf_text_extractor.dart';

final pdfTextExtractorProvider = Provider<PdfTextExtractor>((ref) {
  return AndroidPdfTextExtractor();
});

final fileImportServiceProvider = Provider<FileImportService>((ref) {
  return const FilePickerFileImportService();
});
