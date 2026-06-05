import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:receipts/core/privacy/sanitizer.dart';

typedef LogFileResolver = Future<File> Function();

class ErrorLogService {
  ErrorLogService({
    required this.enabled,
    LogFileResolver? logFileResolver,
  }) : _logFileResolver = logFileResolver;

  final bool enabled;
  final LogFileResolver? _logFileResolver;

  static const _logFileName = 'import_errors.log';

  Future<String> logFilePath() async {
    final file = await _resolveLogFile();
    return file.path;
  }

  Future<void> logImportFailure({
    required String safUri,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
  }) async {
    if (!enabled) {
      return;
    }

    try {
      final file = await _resolveLogFile();
      final safeDetails = PrivacySanitizer.sanitizeDetails(details);
      final payload = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'event': 'import_failure',
        'source': PrivacySanitizer.sourceMarker(safUri),
        'message': message,
        if (error != null) 'errorType': PrivacySanitizer.errorType(error),
        if (stackTrace != null) 'stackTracePresent': true,
        if (safeDetails.isNotEmpty) 'details': safeDetails,
      };

      await file.writeAsString(
        '${jsonEncode(payload)}\n',
        mode: FileMode.append,
      );
    } catch (_) {
      // Ignore logging failures to avoid interfering with the user flow.
    }
  }

  Future<File> _resolveLogFile() async {
    final resolver = _logFileResolver;
    if (resolver != null) {
      return resolver();
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${docsDir.path}/receipts_logs');

    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    return File('${logsDir.path}/$_logFileName');
  }
}
