import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/data/repositories/settings_repository.dart';
import 'package:receipts/features/import/file_import_service.dart';
import 'package:receipts/main.dart';
import 'package:receipts/platform/pdf_text_extractor/pdf_text_extractor.dart';

Future<List<Override>> createIntegrationTestOverrides({
  required FileImportService fileImportService,
  required PdfTextExtractor pdfTextExtractor,
  SettingsRepository? settingsRepository,
  List<Override> additionalOverrides = const [],
}) async {
  final resolvedSettingsRepository = settingsRepository ??
      SettingsRepository(await SharedPreferences.getInstance());

  return [
    fileImportServiceProvider.overrideWithValue(fileImportService),
    pdfTextExtractorProvider.overrideWithValue(pdfTextExtractor),
    settingsRepositoryProvider.overrideWithValue(resolvedSettingsRepository),
    sentryEnabledProvider.overrideWith((ref) {
      return SentryEnabledNotifier(resolvedSettingsRepository, false);
    }),
    ...additionalOverrides,
  ];
}

Widget buildTestApp({List<Override> overrides = const []}) {
  return buildApp(overrides: overrides);
}
