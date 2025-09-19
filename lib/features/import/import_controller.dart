import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biedronka_expenses/app/providers.dart';
import 'package:biedronka_expenses/domain/models/import_result.dart';

class ImportHistoryEntry {
  const ImportHistoryEntry({
    required this.result,
    required this.timestamp,
  });

  final ImportResult result;
  final DateTime timestamp;
}

class ImportController extends AsyncNotifier<List<ImportResult>> {
  final List<ImportHistoryEntry> _history = [];

  List<ImportHistoryEntry> get historyEntries => List.unmodifiable(_history);

  @override
  FutureOr<List<ImportResult>> build() {
    return _history.map((entry) => entry.result).toList();
  }

  Future<void> importUris(List<String> safUris) async {
    if (safUris.isEmpty) {
      return;
    }

    state = const AsyncValue.loading();

    try {
      final importService = ref.read(importServiceProvider);
      final results = await importService.importMany(safUris);
      final newEntries = <ImportHistoryEntry>[];

      for (final result in results) {
        newEntries.add(
          ImportHistoryEntry(
            result: result,
            timestamp: DateTime.now(),
          ),
        );
      }

      if (newEntries.isNotEmpty) {
        _history.insertAll(0, newEntries);
      }

      state = AsyncValue.data(
        _history.map((entry) => entry.result).toList(growable: false),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearHistory() {
    _history.clear();
    state = const AsyncValue.data([]);
  }
}

final importControllerProvider =
    AsyncNotifierProvider<ImportController, List<ImportResult>>(
  () => ImportController(),
);
