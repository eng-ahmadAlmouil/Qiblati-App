import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../features/notifications/data/local_notification_service.dart';

class StartupPermissionsService {
  StartupPermissionsService({LocalNotificationService? notifications})
    : _notifications = notifications ?? LocalNotificationService.instance;

  final LocalNotificationService _notifications;

  Future<void> requestAll() async {
    try {
      await _requestLocation();
    } on MissingPluginException {
      // Native permission APIs are unavailable in widget-test environments.
    }
    try {
      await _notifications.initialize();
    } on MissingPluginException {
      // Native notification APIs are unavailable in widget-test environments.
    }
  }

  Future<void> _requestLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    }
  }
}
