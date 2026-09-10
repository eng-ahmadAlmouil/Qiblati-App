class TafsirAyah {
  const TafsirAyah({
    required this.number,
    required this.numberInSurah,
    required this.text,
  });

  final int number;
  final int numberInSurah;
  final String text;

  factory TafsirAyah.fromJson(Map<String, dynamic> json) {
    final number = json['number'];
    final numberInSurah = json['numberInSurah'];
    final text = json['text'];
    if (number is! int || numberInSurah is! int || text is! String) {
      throw const FormatException('بيانات التفسير ناقصة أو غير صالحة.');
    }
    return TafsirAyah(
      number: number,
      numberInSurah: numberInSurah,
      text: text,
    );
  }
}
