class Ayah {
  const Ayah({required this.number, required this.text, this.page});

  final int number;
  final String text;
  final int? page;

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['numberInSurah'] as int,
      text: (json['text'] as String).replaceFirst('\uFEFF', ''),
      page: json['page'] is int ? json['page'] as int : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'text': text,
    if (page != null) 'page': page,
  };
}
