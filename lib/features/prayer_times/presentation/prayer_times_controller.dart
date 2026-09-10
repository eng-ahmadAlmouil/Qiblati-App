import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../notifications/data/local_notification_service.dart';
import '../../notifications/data/notification_settings_repository.dart';
import '../data/prayer_times_service.dart';
import '../domain/prayer_time.dart';

enum PrayerTimesStatus { idle, loading, ready, error }

class PrayerTimesController extends ChangeNotifier {
  PrayerTimesController({PrayerTimesService? service})
    : _service = service ?? PrayerTimesService(),
      _notificationService = LocalNotificationService.instance;

  final PrayerTimesService _service;
  final LocalNotificationService _notificationService;
  final _settingsRepository = NotificationSettingsRepository();
  PrayerTimesStatus _status = PrayerTimesStatus.idle;
  PrayerTimesResult? _result;
  String? _errorMessage;
  String? _notificationMessage;
  bool _disposed = false;
  static const _cacheKey = 'cached_prayer_times';

  PrayerTimesStatus get status => _status;
  PrayerTimesResult? get result => _result;
  String? get errorMessage => _errorMessage;
  String? get notificationMessage => _notificationMessage;

  void clearNotificationMessage() => _notificationMessage = null;

  Future<void> load({bool forceRefresh = false}) async {
    if (_disposed) return;
    if (!forceRefresh && await _loadCached()) {
      await _scheduleNotifications();
      return;
    }
    _status = PrayerTimesStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _service.fetchToday();
      if (_disposed) return;
      await _saveCached(_result!);
      _status = PrayerTimesStatus.ready;
      await _scheduleNotifications();
    } on PrayerTimesException catch (error) {
      if (_disposed) return;
      _status = PrayerTimesStatus.error;
      _errorMessage = error.message;
    }

    if (!_disposed) notifyListeners();
  }

  Future<void> _scheduleNotifications() async {
    if (_disposed || _result == null) return;
    try {
      final settings = await _settingsRepository.load();
      if (_disposed) return;
      await _notificationService.schedulePrayerNotifications(
        _result!,
        settings,
      );
    } on LocalNotificationException catch (error) {
      _notificationMessage = error.message;
    }
  }

  Future<bool> _loadCached() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_cacheKey);
    if (raw == null) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> ||
          decoded['prayers'] is! List<Object?>) {
        return false;
      }
      final prayers = (decoded['prayers'] as List<Object?>)
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => PrayerTime(
              name: item['name']!.toString(),
              arabicName: item['arabicName']!.toString(),
              time: item['time']!.toString(),
              icon: item['icon']!.toString(),
            ),
          )
          .toList();
      if (prayers.isEmpty) return false;
      _result = PrayerTimesResult(
        date: DateTime.parse(decoded['date']!.toString()),
        timezone: decoded['timezone']?.toString(),
        prayers: prayers,
      );
      _status = PrayerTimesStatus.ready;
      notifyListeners();
      return true;
    } on FormatException {
      return false;
    } on TypeError {
      return false;
    }
  }

  Future<void> _saveCached(PrayerTimesResult result) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _cacheKey,
      jsonEncode({
        'date': result.date.toIso8601String(),
        'timezone': result.timezone,
        'prayers': [
          for (final prayer in result.prayers)
            {
              'name': prayer.name,
              'arabicName': prayer.arabicName,
              'time': prayer.time,
              'icon': prayer.icon,
            },
        ],
      }),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
