import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../domain/notification_preferences.dart';
import '../../prayer_times/domain/prayer_time.dart';
import '../../../app.dart';
import '../presentation/adhan_page.dart';

class LocalNotificationException implements Exception {
  const LocalNotificationException(this.message);

  final String message;
}

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static final instance = LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _exactAlarmsAllowed = false;
  NotificationResponse? _pendingResponse;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = InitializationSettings(
      android: android,
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;
      if (response != null) _onNotificationResponse(response);
    }
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    _exactAlarmsAllowed =
        await androidPlugin?.requestExactAlarmsPermission() ?? false;
    await androidPlugin?.requestFullScreenIntentPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
    if (_pendingResponse != null) {
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        final response = _pendingResponse;
        _pendingResponse = null;
        if (response != null) _onNotificationResponse(response);
      });
    }
  }

  Future<void> schedulePrayerNotifications(
    PrayerTimesResult result,
    NotificationPreferences preferences,
  ) async {
    await initialize();
    await cancelPrayerNotifications();

    if (!preferences.enabled) return;

    final now = DateTime.now();
    for (var index = 0; index < result.prayers.length; index++) {
      final prayer = result.prayers[index];
      final prayerDate = _nextDate(prayer.time, now);
      final noticeDate = prayerDate.subtract(
        Duration(minutes: preferences.minutesBefore),
      );
      await _schedule(
        id: index * 2,
        date: noticeDate.isAfter(now) ? noticeDate : prayerDate,
        title: 'اقترب موعد الصلاة',
        body:
            'تبقى ${preferences.minutesBefore} دقائق على أذان ${prayer.arabicName}.',
        sound: false,
        prayerName: prayer.arabicName,
      );
      await _schedule(
        id: index * 2 + 1,
        date: prayerDate,
        title: 'حان الآن موعد الأذان',
        body: 'حان الآن موعد أذان ${prayer.arabicName}.',
        sound: preferences.mode == NotificationMode.adhan,
        prayerName: prayer.arabicName,
      );
    }
  }

  Future<void> cancelPrayerNotifications() => _plugin.cancelAll();

  Future<void> stopAdhan(int notificationId) =>
      _plugin.cancel(id: notificationId);

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || !payload.startsWith('adhan:')) return;
    final prayerName = payload.substring('adhan:'.length);
    final navigator = QiblatiApp.navigatorKey.currentState;
    if (navigator == null) {
      _pendingResponse = response;
      return;
    }
    navigator.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AdhanPage(
          prayerName: prayerName,
          notificationId: response.id ?? -1,
        ),
      ),
    );
  }

  Future<void> _schedule({
    required int id,
    required DateTime date,
    required String title,
    required String body,
    required bool sound,
    required String prayerName,
  }) {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        sound ? 'prayer_adhan_v3' : 'prayer_times',
        'مواقيت الصلاة',
        channelDescription: 'تنبيهات اقتراب ودخول أوقات الصلاة',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        fullScreenIntent: sound,
        ongoing: sound,
        autoCancel: !sound,
        category: sound ? AndroidNotificationCategory.alarm : null,
        visibility: sound ? NotificationVisibility.public : null,
        audioAttributesUsage: sound
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        sound: sound
            ? const RawResourceAndroidNotificationSound('adhan')
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
        sound: sound ? 'adhan.aiff' : null,
      ),
    );

    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      payload: sound ? 'adhan:$prayerName' : null,
      scheduledDate: tz.TZDateTime.from(date, tz.local),
      notificationDetails: details,
      androidScheduleMode: _exactAlarmsAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  DateTime _nextDate(String time, DateTime now) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    var date = DateTime(now.year, now.month, now.day, hour, minute);
    if (!date.isAfter(now)) date = date.add(const Duration(days: 1));
    return date;
  }
}
