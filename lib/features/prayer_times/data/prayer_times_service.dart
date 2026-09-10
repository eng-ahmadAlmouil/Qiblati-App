import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../domain/prayer_time.dart';

class PrayerTimesException implements Exception {
  const PrayerTimesException(this.message);

  final String message;
}

class PrayerTimesService {
  PrayerTimesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<PrayerTimesResult> fetchToday() async {
    final position = await _currentPosition();
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-${now.year}';
    final uri = Uri.https('api.aladhan.com', '/v1/timings/$date', {
      'latitude': position.latitude.toString(),
      'longitude': position.longitude.toString(),
      'method': '4',
    });

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const PrayerTimesException('انتهى وقت الاتصال بخدمة المواقيت.');
    } on http.ClientException {
      throw const PrayerTimesException('تعذر الاتصال بخدمة المواقيت.');
    }
    if (response.statusCode != 200) {
      throw PrayerTimesException(
        'تعذر تحميل المواقيت (${response.statusCode}).',
      );
    }

    late final Object? json;
    try {
      json = jsonDecode(response.body);
    } on FormatException {
      throw const PrayerTimesException('وصلت بيانات المواقيت بصيغة غير صالحة.');
    }
    if (json is! Map<String, dynamic> ||
        json['data'] is! Map<String, dynamic>) {
      throw const PrayerTimesException(
        'وصلت بيانات المواقيت بصيغة غير متوقعة.',
      );
    }

    final data = json['data'] as Map<String, dynamic>;
    final timings = data['timings'];
    if (timings is! Map<String, dynamic>) {
      throw const PrayerTimesException('لم يتم العثور على مواقيت الصلاة.');
    }

    final meta = data['meta'];
    final timezone = meta is Map<String, dynamic>
        ? meta['timezone']?.toString()
        : null;

    return PrayerTimesResult(
      date: now,
      timezone: timezone,
      prayers: PrayerTime.fromTimings(timings),
    );
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const PrayerTimesException('خدمة الموقع متوقفة.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PrayerTimesException('لم يتم السماح بالوصول إلى الموقع.');
    }

    return Geolocator.getCurrentPosition();
  }
}
