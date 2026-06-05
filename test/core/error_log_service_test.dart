import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/core/logging/error_log_service.dart';

void main() {
  test('disabled import failure logging is a no-op', () async {
    var resolverCalled = false;
    final logger = ErrorLogService(
      enabled: false,
      logFileResolver: () async {
        resolverCalled = true;
        return File('unused.log');
      },
    );

    await logger.logImportFailure(
      safUri: 'content://provider/private/receipt.pdf',
      message: 'safe message',
    );

    expect(resolverCalled, isFalse);
  });

  test('import failure logging writes only safe allowlisted fields', () async {
    final directory = await Directory.systemTemp.createTemp(
      'reseipts_error_log_test_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final logFile = File('${directory.path}/import_errors.log');
    final logger = ErrorLogService(
      enabled: true,
      logFileResolver: () async => logFile,
    );

    await logger.logImportFailure(
      safUri: 'content://provider/private/receipt.pdf',
      message: 'safe message',
      error: StateError('NIP 1234567890 at /Users/me/receipt.pdf'),
      stackTrace: StackTrace.fromString(
        'content://provider/private/receipt.pdf',
      ),
      details: {
        'stage': 'normalized_text_empty',
        'ocr': 'empty',
        'message': 'content://provider/private/receipt.pdf',
        'source': '/Users/me/receipt.pdf',
        'nested': {'raw': 'receipt text'},
      },
    );

    final rawLog = await logFile.readAsString();
    final payload = jsonDecode(rawLog.trim()) as Map<String, dynamic>;

    expect(payload['event'], 'import_failure');
    expect(payload['source'], 'redacted');
    expect(payload['message'], 'safe message');
    expect(payload['errorType'], 'StateError');
    expect(payload['stackTracePresent'], isTrue);
    expect(payload.containsKey('error'), isFalse);
    expect(payload.containsKey('stackTrace'), isFalse);
    expect(payload['details'], {
      'stage': 'normalized_text_empty',
      'ocr': 'empty',
    });

    expect(rawLog, isNot(contains('content://provider/private')));
    expect(rawLog, isNot(contains('/Users/me')));
    expect(rawLog, isNot(contains('1234567890')));
    expect(rawLog, isNot(contains('receipt text')));
  });
}
