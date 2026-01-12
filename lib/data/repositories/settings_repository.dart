import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository(this._preferences);

  final SharedPreferences _preferences;
  static const _sentryEnabledKey = 'sentry_enabled';
  static const _devLoggingEnabledKey = 'dev_logging_enabled';

  bool isSentryEnabled() => _preferences.getBool(_sentryEnabledKey) ?? false;
  bool isDevLoggingEnabled() =>
      _preferences.getBool(_devLoggingEnabledKey) ?? false;

  Future<void> setSentryEnabled(bool value) async {
    await _preferences.setBool(_sentryEnabledKey, value);
  }

  Future<void> setDevLoggingEnabled(bool value) async {
    await _preferences.setBool(_devLoggingEnabledKey, value);
  }
}
