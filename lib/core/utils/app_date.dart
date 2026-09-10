abstract final class AppDate {
  static String gregorian(DateTime date) =>
      '${_weekdays[date.weekday - 1]}، ${date.day} ${_gregorianMonths[date.month - 1]} ${date.year}';

  static String hijri(DateTime date) {
    final jd = _julianDay(date.year, date.month, date.day);
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    final adjusted = l - 10631 * n + 354;
    final j =
        (((10985 - adjusted) / 5316).floor() *
            ((50 * adjusted / 17719).floor())) +
        ((adjusted / 5670).floor() * ((43 * adjusted / 15238).floor()));
    final adjusted2 =
        adjusted -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    final month = ((24 * adjusted2) / 709).floor();
    final day = adjusted2 - ((709 * month) / 24).floor();
    final year = 30 * n + j - 30;
    return '$day ${_months[month - 1]} $year هـ';
  }

  static int _julianDay(int year, int month, int day) {
    final a = ((14 - month) / 12).floor();
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        ((153 * m + 2) / 5).floor() +
        365 * y +
        (y / 4).floor() -
        (y / 100).floor() +
        (y / 400).floor() -
        32045;
  }

  static const _months = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const _weekdays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const _gregorianMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
}
