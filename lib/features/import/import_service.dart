import 'package:receipts/application/import/import_receipt_use_case.dart';
import 'package:receipts/core/logging/error_log_service.dart';
import 'package:receipts/data/repositories/analytics_repository.dart';
import 'package:receipts/data/repositories/receipt_repository.dart';
import 'package:receipts/domain/models/import_result.dart';
import 'package:receipts/domain/parsing/receipt_parser.dart';
import 'package:receipts/platform/pdf_text_extractor/pdf_text_extractor.dart';

class ImportService {
  ImportService({
    required PdfTextExtractor pdf,
    required ReceiptParser parser,
    required ReceiptRepository receipts,
    required AnalyticsRepository analytics,
    required ErrorLogService errorLogger,
  }) : _useCase = ImportReceiptUseCase(
          pdf: pdf,
          parser: parser,
          receipts: receipts,
          analytics: analytics,
          errorLogger: errorLogger,
        );

  final ImportReceiptUseCase _useCase;

  Future<ImportResult> importOne(String safUri) => _useCase.importOne(safUri);

  Future<List<ImportResult>> importMany(List<String> safUris) =>
      _useCase.importMany(safUris);
}
