class Surah {
  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.versesCount,
    required this.revelationPlace,
  });

  final int number;
  final String name;
  final String englishName;
  final int versesCount;
  final String revelationPlace;

  factory Surah.fromJson(Map<String, dynamic> json) {
    final number = json['number'];
    final name = json['name'];
    final englishName = json['englishName'];
    final versesCount = json['numberOfAyahs'] ?? json['versesCount'];
    final revelationType = json['revelationType'];
    if (number is! int ||
        name is! String ||
        englishName is! String ||
        versesCount is! int) {
      throw const FormatException('بيانات السورة ناقصة أو غير صالحة.');
    }
    return Surah(
      number: number,
      name: name.replaceAll('سُورَةُ ', ''),
      englishName: englishName,
      versesCount: versesCount,
      revelationPlace: revelationType == 'Meccan' ? 'مكية' : 'مدنية',
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'name': name,
    'englishName': englishName,
    'versesCount': versesCount,
    'revelationPlace': revelationPlace,
  };

  String get displayName => _withoutDiacritics(name);

  static String _withoutDiacritics(String value) => value
      .replaceAll(
        RegExp(r'[\u0617-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
        '',
      )
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي');
}
