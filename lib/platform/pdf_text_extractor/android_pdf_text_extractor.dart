import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'pdf_text_extractor.dart';

class AndroidPdfTextExtractor implements PdfTextExtractor {
  static const _channel = MethodChannel('pdf_text_extractor');

  @override
  Future<List<String>> extractTextPages(String safUri) async {
    try {
      // During development, return sample data from assets if no real PDF
      if (kDebugMode && safUri.contains('sample')) {
        return await _getSampleReceiptText();
      }

      final result = await _channel.invokeMethod('extractTextPages', safUri);
      return List<String>.from(result);
    } on PlatformException catch (e) {
      throw PdfTextExtractionException(
        'Failed to extract text: ${e.message}',
        e.details?.toString(),
      );
    }
  }

  @override
  Future<int> pageCount(String safUri) async {
    try {
      if (kDebugMode && safUri.contains('sample')) {
        return 1;
      }

      return await _channel.invokeMethod('pageCount', safUri);
    } on PlatformException catch (e) {
      throw PdfTextExtractionException(
        'Failed to get page count: ${e.message}',
        e.details?.toString(),
      );
    }
  }

  @override
  Future<String> fileHash(String safUri) async {
    try {
      if (kDebugMode && safUri.contains('sample')) {
        return 'sample_receipt_hash_123';
      }

      return await _channel.invokeMethod('fileHash', safUri);
    } on PlatformException catch (e) {
      throw PdfTextExtractionException(
        'Failed to compute file hash: ${e.message}',
        e.details?.toString(),
      );
    }
  }

  @override
  Future<String> readTextFile(String safUri) async {
    try {
      if (kDebugMode && safUri.contains('sample_json')) {
        return await rootBundle.loadString('assets/sample_receipt.json');
      }

      return await _channel.invokeMethod('readTextFile', safUri);
    } on PlatformException catch (e) {
      throw PdfTextExtractionException(
        'Failed to read text file: ${e.message}',
        e.details?.toString(),
      );
    }
  }

  Future<List<String>> _getSampleReceiptText() async {
    try {
      final assetText =
          await rootBundle.loadString('assets/sample_receipt.txt');
      return [assetText];
    } catch (e) {
      // Fallback sample receipt text
      return [_fallbackSampleText];
    }
  }

  static const String _fallbackSampleText = '''
Receipts Sp. z o.o.
ul. Zielona 10
00-001 Warszawa
NIP: 0000000000

Paragon fiskalny
14.08.2025 18:22

Mleko 2%                    2,00 szt
3,20 PLN/szt                   6,40 PLN A

Chleb pszenny               1,00 szt
4,50 PLN/szt                   4,50 PLN A

Ser żółty                   0,500 kg
29,00 PLN/kg                  14,50 PLN B

RABAT promocja                -2,00 PLN

SUMA PLN                      23,40

Gotówka                       25,00 PLN
Reszta                         1,60 PLN

VAT A 5%    podstawa    6,09  VAT    0,30
VAT B 8%    podstawa   13,43  VAT    1,07
SUMA VAT                       1,37

Dziękujemy za zakupy
''';
}
