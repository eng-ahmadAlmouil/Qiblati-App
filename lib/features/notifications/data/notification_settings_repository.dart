import 'package:shared_preferences/shared_preferences.dart';

import '../domain/notification_preferences.dart';

class NotificationSettingsRepository {
  static const _enabledKey = 'notifications_enabled';
  static const _modeKey = 'notifications_mode';
  static const _minutesBeforeKey = 'notifications_minutes_before';

  Future<NotificationPreferences> load() async {
    final preferences = await SharedPreferences.getInstance();
    final mode = preferences.getString(_modeKey);

    return NotificationPreferences(
      enabled: preferences.getBool(_enabledKey) ?? true,
      mode: mode == NotificationMode.adhan.name
          ? NotificationMode.adhan
          : NotificationMode.voiceNotice,
      minutesBefore: preferences.getInt(_minutesBeforeKey) ?? 3,
    );
  }

  Future<void> save(NotificationPreferences settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, settings.enabled);
    await preferences.setString(_modeKey, settings.mode.name);
    await preferences.setInt(_minutesBeforeKey, settings.minutesBefore);
  }
}
