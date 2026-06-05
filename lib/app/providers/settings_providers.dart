import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/core/logging/error_log_service.dart';
import 'package:receipts/data/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('SettingsRepository must be provided at runtime');
});

class SentryEnabledNotifier extends StateNotifier<bool> {
  SentryEnabledNotifier(this._repository, bool initialState)
      : super(initialState);

  final SettingsRepository _repository;

  Future<void> setEnabled(bool value) async {
    if (state == value) {
      return;
    }
    state = value;
    await _repository.setSentryEnabled(value);
  }
}

final sentryEnabledProvider =
    StateNotifierProvider<SentryEnabledNotifier, bool>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SentryEnabledNotifier(repository, false);
});

class DevLoggingEnabledNotifier extends StateNotifier<bool> {
  DevLoggingEnabledNotifier(this._repository, bool initialState)
      : super(initialState);

  final SettingsRepository _repository;

  Future<void> setEnabled(bool value) async {
    if (state == value) {
      return;
    }
    state = value;
    await _repository.setDevLoggingEnabled(value);
  }
}

final devLoggingEnabledProvider =
    StateNotifierProvider<DevLoggingEnabledNotifier, bool>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return DevLoggingEnabledNotifier(repository, false);
});

final errorLogServiceProvider = Provider<ErrorLogService>((ref) {
  final devLoggingEnabled = ref.watch(devLoggingEnabledProvider);
  return ErrorLogService(enabled: devLoggingEnabled);
});

final errorLogPathProvider = FutureProvider<String>((ref) async {
  final logger = ref.watch(errorLogServiceProvider);
  return logger.logFilePath();
});
