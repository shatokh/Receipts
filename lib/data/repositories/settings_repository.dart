import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository(this._preferences);

  final SharedPreferences _preferences;
  static const _sentryEnabledKey = 'sentry_enabled';

  bool isSentryEnabled() => _preferences.getBool(_sentryEnabledKey) ?? false;

  Future<void> setSentryEnabled(bool value) async {
    await _preferences.setBool(_sentryEnabledKey, value);
  }
}
