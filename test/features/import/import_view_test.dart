import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/domain/models/import_result.dart';
import 'package:receipts/features/import/import_controller.dart';
import 'package:receipts/features/import/import_view.dart';
import 'package:receipts/l10n/app_localizations.dart';

void main() {
  testWidgets('ImportView shows loading state without empty state underneath',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importControllerProvider.overrideWith(_LoadingImportController.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ImportView(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
        find.text(
            'Performing OCR. The first run may take longer while text recognition models download.'),
        findsOneWidget);
    expect(find.text('No imports yet'), findsNothing);
    expect(find.text('Import your first receipt (PDF or JSON)'), findsNothing);
  });
}

class _LoadingImportController extends ImportController {
  @override
  FutureOr<List<ImportResult>> build() {
    return Completer<List<ImportResult>>().future;
  }
}
