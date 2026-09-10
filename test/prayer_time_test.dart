import 'package:flutter_test/flutter_test.dart';

import 'package:qiblati/features/prayer_times/domain/prayer_time.dart';

void main() {
  test('maps API timings to the Arabic prayer schedule', () {
    final prayers = PrayerTime.fromTimings({
      'Fajr': '04:12 (EET)',
      'Dhuhr': '12:05 (EET)',
      'Asr': '15:31 (EET)',
      'Maghrib': '18:42 (EET)',
      'Isha': '20:01 (EET)',
    });

    expect(prayers.length, 5);
    expect(prayers.first.arabicName, 'الفجر');
    expect(prayers.first.time, '04:12');
    expect(prayers.last.arabicName, 'العشاء');
  });
}
