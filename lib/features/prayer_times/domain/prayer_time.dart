class PrayerTime {
  const PrayerTime({
    required this.name,
    required this.arabicName,
    required this.time,
    required this.icon,
  });

  final String name;
  final String arabicName;
  final String time;
  final String icon;

  static List<PrayerTime> fromTimings(Map<String, dynamic> timings) {
    const prayers = [
      ('Fajr', 'الفجر', '🌙'),
      ('Dhuhr', 'الظهر', '☀️'),
      ('Asr', 'العصر', '🌤️'),
      ('Maghrib', 'المغرب', '🌅'),
      ('Isha', 'العشاء', '✨'),
    ];

    return [
      for (final prayer in prayers)
        PrayerTime(
          name: prayer.$1,
          arabicName: prayer.$2,
          time: _cleanTime(timings[prayer.$1]),
          icon: prayer.$3,
        ),
    ];
  }

  static String _cleanTime(Object? value) {
    final raw = value?.toString() ?? '--:--';
    return raw.split(' ').first;
  }
}

class PrayerTimesResult {
  const PrayerTimesResult({
    required this.date,
    required this.timezone,
    required this.prayers,
  });

  final DateTime date;
  final String? timezone;
  final List<PrayerTime> prayers;
}
