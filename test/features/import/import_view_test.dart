import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/domain/models/import_result.dart';
import 'package:receipts/features/import/import_controller.dart';
import 'package:receipts/features/import/import_view.dart';
import 'package:receipts/l10n/app_localizations.dart';

void main() {
  testWidgets('ImportView renders empty state', (tester) async {
    await _pumpImportView(
      tester,
      controllerFactory: () => _SeededImportController(),
    );

    expect(find.text('No imports yet'), findsOneWidget);
    expect(
        find.text('Import your first receipt (PDF or JSON)'), findsOneWidget);
    expect(find.byKey(const ValueKey('import_status_success')), findsNothing);
    expect(find.byKey(const ValueKey('import_status_duplicate')), findsNothing);
    expect(find.byKey(const ValueKey('import_status_error')), findsNothing);
  });

  testWidgets('ImportView shows loading state without empty state underneath',
      (tester) async {
    await _pumpImportView(
      tester,
      controllerFactory: _LoadingImportController.new,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
        find.text(
            'Performing OCR. The first run may take longer while text recognition models download.'),
        findsOneWidget);
    expect(find.text('No imports yet'), findsNothing);
    expect(find.text('Import your first receipt (PDF or JSON)'), findsNothing);
  });

  testWidgets('ImportView renders successful import history item',
      (tester) async {
    await _pumpImportView(
      tester,
      controllerFactory: () => _SeededImportController(
        entries: [
          _historyEntry(
            const ImportResult(
              sourceUri: 'asset:///sample.pdf',
              status: ImportStatus.success,
              receiptId: 'receipt-1',
            ),
          ),
        ],
      ),
    );

    expect(find.text('sample.pdf'), findsOneWidget);
    expect(find.byKey(const ValueKey('import_status_success')), findsOneWidget);
    expect(find.byKey(const ValueKey('import_status_duplicate')), findsNothing);
    expect(find.byKey(const ValueKey('import_status_error')), findsNothing);
    expect(find.text('Retry OCR'), findsNothing);
  });

  testWidgets('ImportView renders duplicate import history item',
      (tester) async {
    await _pumpImportView(
      tester,
      controllerFactory: () => _SeededImportController(
        entries: [
          _historyEntry(
            const ImportResult(
              sourceUri: 'asset:///duplicate.pdf',
              status: ImportStatus.duplicate,
              message: 'heuristic',
            ),
          ),
        ],
      ),
    );

    expect(find.text('duplicate.pdf'), findsOneWidget);
    expect(find.textContaining('heuristic'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('import_status_duplicate')),
      findsOneWidget,
    );
    expect(find.text('Retry OCR'), findsNothing);
  });

  testWidgets('ImportView renders error history item with retry action',
      (tester) async {
    final controller = _SeededImportController(
      entries: [
        _historyEntry(
          const ImportResult(
            sourceUri: 'content://provider/private/broken.pdf',
            status: ImportStatus.error,
            message:
                'The receipt file could not be parsed because its structure is invalid.',
          ),
        ),
      ],
    );

    await _pumpImportView(
      tester,
      controllerFactory: () => controller,
    );

    expect(find.text('broken.pdf'), findsOneWidget);
    expect(
      find.textContaining(
        'The receipt file could not be parsed because its structure is invalid.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('content://provider/private'), findsNothing);
    expect(find.byKey(const ValueKey('import_status_error')), findsOneWidget);
    expect(find.text('Retry OCR'), findsOneWidget);

    await tester.tap(find.text('Retry OCR'));
    await tester.pump();

    expect(controller.retriedUris, ['content://provider/private/broken.pdf']);
  });

  testWidgets('ImportView renders partial batch result history',
      (tester) async {
    await _pumpImportView(
      tester,
      controllerFactory: () => _SeededImportController(
        entries: [
          _historyEntry(
            const ImportResult(
              sourceUri: 'asset:///imported.pdf',
              status: ImportStatus.success,
              receiptId: 'receipt-1',
            ),
          ),
          _historyEntry(
            const ImportResult(
              sourceUri: 'asset:///duplicate.pdf',
              status: ImportStatus.duplicate,
              message: 'hash',
            ),
          ),
          _historyEntry(
            const ImportResult(
              sourceUri: 'asset:///failed.pdf',
              status: ImportStatus.error,
              message:
                  'Unable to extract text from the PDF. OCR models may still be downloading. Use Retry OCR after the download completes or import the JSON export from the Receipts app.',
            ),
          ),
        ],
      ),
    );

    expect(find.text('imported.pdf'), findsOneWidget);
    expect(find.text('duplicate.pdf'), findsOneWidget);
    expect(find.text('failed.pdf'), findsOneWidget);
    expect(find.byKey(const ValueKey('import_status_success')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('import_status_duplicate')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('import_status_error')), findsOneWidget);
    expect(find.text('Retry OCR'), findsOneWidget);
  });
}

Future<void> _pumpImportView(
  WidgetTester tester, {
  required ImportController Function() controllerFactory,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        importControllerProvider.overrideWith(controllerFactory),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ImportView(),
      ),
    ),
  );

  await tester.pump();
}

ImportHistoryEntry _historyEntry(ImportResult result) {
  return ImportHistoryEntry(
    result: result,
    timestamp: DateTime.now(),
  );
}

class _LoadingImportController extends ImportController {
  @override
  FutureOr<List<ImportResult>> build() {
    return Completer<List<ImportResult>>().future;
  }
}

class _SeededImportController extends ImportController {
  _SeededImportController({List<ImportHistoryEntry> entries = const []})
      : _entries = entries;

  final List<ImportHistoryEntry> _entries;
  final List<String> retriedUris = [];

  @override
  List<ImportHistoryEntry> get historyEntries => List.unmodifiable(_entries);

  @override
  FutureOr<List<ImportResult>> build() {
    return _entries.map((entry) => entry.result).toList(growable: false);
  }

  @override
  Future<void> importUris(List<String> safUris) async {
    retriedUris.addAll(safUris);
  }
}
