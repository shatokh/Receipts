import 'dart:convert';
import 'dart:developer' as developer;

import 'package:receipts/core/logging/error_log_service.dart';
import 'package:receipts/core/privacy/sanitizer.dart';
import 'package:receipts/data/repositories/analytics_repository.dart';
import 'package:receipts/data/repositories/receipt_repository.dart';
import 'package:receipts/domain/models/import_result.dart';
import 'package:receipts/domain/models/receipt.dart';
import 'package:receipts/domain/parsing/receipt_parser.dart';
import 'package:receipts/platform/pdf_text_extractor/pdf_text_extractor.dart';

class ImportReceiptUseCase {
  ImportReceiptUseCase({
    required this.pdf,
    required this.parser,
    required this.receipts,
    required this.analytics,
    required this.errorLogger,
  });

  final PdfTextExtractor pdf;
  final ReceiptParser parser;
  final ReceiptRepository receipts;
  final AnalyticsRepository analytics;
  final ErrorLogService errorLogger;

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

      return ImportResult(
        sourceUri: safUri,
        status: ImportStatus.success,
        receiptId: savedId,
      );
    } catch (error, stackTrace) {
      final mappedMessage = _mapImportError(error);
      final logDetails = _extractLogDetails(error);
      developer.log(
        'Failed to import receipt',
        name: 'ImportReceiptUseCase',
        error: jsonEncode({
          'errorType': PrivacySanitizer.errorType(error),
          'details': PrivacySanitizer.sanitizeDetails(logDetails),
        }),
      );
      await errorLogger.logImportFailure(
        safUri: safUri,
        message: mappedMessage,
        error: error,
        stackTrace: stackTrace,
        details: logDetails,
      );
      return ImportResult(
        sourceUri: safUri,
        status: ImportStatus.error,
        message: mappedMessage,
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
      if (pages.isEmpty) {
        throw const FormatException(
          'PDF does not contain any machine-readable text or embedded receipt data.',
        );
      }

      final text = _normalizeExtractedText(pages);
      if (text.trim().isEmpty) {
        throw const FormatException(
          'PDF does not contain any machine-readable text or embedded receipt data.',
        );
      }

      return parser.parse(text);
    } on FormatException catch (error) {
      if (_isEmptyPdfFormatError(error)) {
        _recordExtractionTelemetry(
          safUri: safUri,
          outcome: 'normalized_text_empty',
          details: {'message': error.message},
        );
        return _parseTextFileOrRethrow(safUri, error);
      }
      rethrow;
    } on PdfTextExtractionException catch (error) {
      final stageDetails = _decodeStageDetails(error.details);
      _recordExtractionTelemetry(
        safUri: safUri,
        outcome: 'empty_pdf_text',
        details: stageDetails ?? {'message': error.message},
      );
      return _parseTextFileOrRethrow(
        safUri,
        error,
        stageDetails: stageDetails,
      );
    }
  }

  Future<Receipt> _parseTextFileOrRethrow(
    String safUri,
    Object extractionError, {
    Map<String, dynamic>? stageDetails,
  }) async {
    try {
      return await _parseTextFile(safUri);
    } on FormatException catch (_) {
      if (extractionError is PdfTextExtractionException) {
        throw PdfTextExtractionException(
          extractionError.message,
          extractionError.details ?? jsonEncode(stageDetails ?? {}),
        );
      }

      if (extractionError is FormatException) {
        throw extractionError;
      }

      throw const FormatException(
        'The receipt file could not be parsed because its structure is invalid.',
      );
    }
  }

  Future<Receipt> _parseTextFile(String safUri) async {
    final raw = await pdf.readTextFile(safUri);
    final trimmed = raw.trimLeft();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty file');
    }
    if (!trimmed.startsWith('{')) {
      throw const FormatException(
        'Unsupported receipt source. Please provide a JSON export generated by the Receipts app.',
      );
    }
    return parser.parse(trimmed);
  }

  String _mapImportError(Object error) {
    if (error is FormatException) {
      final message = error.message;
      if (message.isEmpty) {
        return 'The receipt file could not be parsed because its structure is invalid.';
      }
      return _safeFormatMessage(message);
    }
    if (error is PdfTextExtractionException) {
      final stageDetails = _decodeStageDetails(error.details);
      final ocrStatus = stageDetails?['ocr']?.toString();
      if (ocrStatus == 'empty' || ocrStatus == 'error') {
        return 'Unable to extract text from the PDF. OCR models may still be downloading. Use Retry OCR after the download completes or import the JSON export from the Receipts app.';
      }
      return 'The receipt file could not be read. Please try again or import the JSON export from the Receipts app.';
    }
    return 'Unexpected error while importing the receipt. Please try again.';
  }

  String _safeFormatMessage(String message) {
    const safeMessages = {
      'PDF does not contain any machine-readable text or embedded receipt data.',
      'Empty file',
      'Unsupported receipt source. Please provide a JSON export generated by the Receipts app.',
      'Unsupported receipt JSON payload',
      'Unsupported receipt source',
      'Missing purchase date',
      'Missing total amount',
      'The receipt file could not be parsed because its structure is invalid.',
    };

    if (safeMessages.contains(message)) {
      return message;
    }
    return 'The receipt file could not be parsed because its structure is invalid.';
  }

  String _normalizeExtractedText(List<String> pages) {
    final buffer = StringBuffer();
    for (final page in pages) {
      final normalized = page.replaceAll('\u0000', '').trimRight();
      buffer
        ..write(normalized)
        ..write('\n');
    }
    return buffer.toString().trimRight();
  }

  void _recordExtractionTelemetry({
    required String safUri,
    required String outcome,
    Map<String, dynamic>? details,
  }) {
    analytics.recordImportTelemetry(
      sourceUri: safUri,
      stage: outcome,
      details: details ?? const {},
    );
  }

  Map<String, dynamic>? _extractLogDetails(Object error) {
    if (error is PdfTextExtractionException) {
      return _decodeStageDetails(error.details);
    }

    if (error is FormatException && _isEmptyPdfFormatError(error)) {
      return {'stage': 'normalized_text_empty'};
    }

    return null;
  }

  Map<String, dynamic>? _decodeStageDetails(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // ignore malformed detail payloads
    }

    return null;
  }

  bool _isEmptyPdfFormatError(FormatException error) {
    final normalized = error.message.toLowerCase();
    return normalized.contains('machine-readable text') ||
        normalized.contains('pdf does not contain');
  }
}
