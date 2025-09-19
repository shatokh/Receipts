import 'package:biedronka_expenses/data/repositories/analytics_repository.dart';
import 'package:biedronka_expenses/data/repositories/receipt_repository.dart';
import 'package:biedronka_expenses/domain/models/import_result.dart';
import 'package:biedronka_expenses/domain/parsing/receipt_parser.dart';
import 'package:biedronka_expenses/platform/pdf_text_extractor/pdf_text_extractor.dart';

class ImportService {
  ImportService({
    required this.pdf,
    required this.parser,
    required this.receipts,
    required this.analytics,
  });

  final PdfTextExtractor pdf;
  final ReceiptParser parser;
  final ReceiptRepository receipts;
  final AnalyticsRepository analytics;

  Future<ImportResult> importOne(String safUri) async {
    try {
      final hash = await pdf.fileHash(safUri);
      if (await receipts.existsByHash(hash)) {
        return ImportResult(
          sourceUri: safUri,
          status: ImportStatus.duplicate,
          message: 'hash',
        );
      }

      final pages = await pdf.extractTextPages(safUri);
      final text = pages.join('\n');
      final parsedReceipt = parser.parse(text);
      final receipt = parsedReceipt.copyWith(sourceUri: safUri, fileHash: hash);

      if (await receipts.isDuplicateByHeuristic(receipt)) {
        return ImportResult(
          sourceUri: safUri,
          status: ImportStatus.duplicate,
          message: 'heuristic',
        );
      }

      final savedId = await receipts.insertReceiptWithItems(
        receipt: receipt,
        items: receipt.items,
      );

      final monthStart =
          DateTime(receipt.purchaseTs.year, receipt.purchaseTs.month, 1);
      await analytics.updateAggregatesForMonth(monthStart);

      return ImportResult(
        sourceUri: safUri,
        status: ImportStatus.success,
        receiptId: savedId,
      );
    } catch (error) {
      return ImportResult(
        sourceUri: safUri,
        status: ImportStatus.error,
        message: error.toString(),
      );
    }
  }

  Future<List<ImportResult>> importMany(List<String> safUris) async {
    final results = <ImportResult>[];
    for (final uri in safUris) {
      results.add(await importOne(uri));
    }
    return results;
  }
}
