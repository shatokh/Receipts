import 'package:receipts/data/repositories/analytics_repository.dart';
import 'package:receipts/data/repositories/receipt_repository.dart';
import 'package:receipts/domain/models/import_result.dart';
import 'package:receipts/domain/models/receipt.dart';
import 'package:receipts/domain/parsing/receipt_parser.dart';
import 'package:receipts/platform/pdf_text_extractor/pdf_text_extractor.dart';

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

      final parsedReceipt = await _parseReceipt(safUri);
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

  Future<Receipt> _parseReceipt(String safUri) async {
    try {
      final pages = await pdf.extractTextPages(safUri);
      final text = pages.join('\n');
      return parser.parse(text);
    } on PdfTextExtractionException {
      return _parseTextFile(safUri);
    } on FormatException {
      return _parseTextFile(safUri);
    }
  }

  Future<Receipt> _parseTextFile(String safUri) async {
    final raw = await pdf.readTextFile(safUri);
    final trimmed = raw.trimLeft();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty file');
    }
    if (!trimmed.startsWith('{')) {
      throw const FormatException('Unsupported receipt source');
    }
    return parser.parse(trimmed);
  }
}
