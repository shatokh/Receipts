import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/app/router.dart';
import 'package:receipts/core/logging/error_log_service.dart';
import 'package:receipts/data/database.dart';
import 'package:receipts/di/test_overrides.dart';

import '../../test/test_infra/fakes/fake_file_import_service.dart';

class DeviceTestHarness {
  DeviceTestHarness._({
    required this.fileImportService,
    required this.pdfTextExtractor,
    required this.errorLogger,
    required this.overrides,
  });

  final FakeFileImportService fileImportService;
  final FakePdfTextExtractor pdfTextExtractor;
  final RecordingErrorLogService errorLogger;
  final List<Override> overrides;

  static Future<void> configureForAndroid() async {
    SharedPreferences.setMockInitialValues({});
    DatabaseHelper.configureForTesting(
      databaseName: 'integration_test.db',
      useFfi: false,
    );
  }

  static Future<DeviceTestHarness> create() async {
    SharedPreferences.setMockInitialValues({});
    final fileImportService = FakeFileImportService();
    final pdfTextExtractor = FakePdfTextExtractor(fileImportService);
    final errorLogger = RecordingErrorLogService();

    await DatabaseHelper.close();
    final databasesPath = await getDatabasesPath();
    await deleteDatabase(path.join(databasesPath, 'integration_test.db'));
    router.go('/onboarding');

    final overrides = await createIntegrationTestOverrides(
      fileImportService: fileImportService,
      pdfTextExtractor: pdfTextExtractor,
      additionalOverrides: [
        errorLogServiceProvider.overrideWithValue(errorLogger),
      ],
    );

    return DeviceTestHarness._(
      fileImportService: fileImportService,
      pdfTextExtractor: pdfTextExtractor,
      errorLogger: errorLogger,
      overrides: overrides,
    );
  }

  Widget buildApp() => buildTestApp(overrides: overrides);

  Future<void> dispose() async {
    fileImportService.clear();
    await DatabaseHelper.close();
  }
}

class RecordingErrorLogService extends ErrorLogService {
  RecordingErrorLogService() : super(enabled: false);

  String? lastErrorType;

  @override
  Future<void> logImportFailure({
    required String safUri,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
  }) async {
    lastErrorType = error == null ? 'unknown error' : error.runtimeType.toString();
  }
}
