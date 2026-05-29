import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ErrorLogService {
  ErrorLogService({required this.enabled});

  final bool enabled;

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
      final payload = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'source': safUri,
        'message': message,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
        if (details != null && details.isNotEmpty) 'details': details,
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
    final docsDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${docsDir.path}/receipts_logs');

    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    return File('${logsDir.path}/$_logFileName');
  }
}
