import '../domain/surah.dart';

class SurahRepository {
  const SurahRepository();

  List<Surah> getAll() => const [
    Surah(
      number: 1,
      name: 'الفاتحة',
      englishName: 'Al-Fatihah',
      versesCount: 7,
      revelationPlace: 'مكية',
    ),
    Surah(
      number: 2,
      name: 'البقرة',
      englishName: 'Al-Baqarah',
      versesCount: 286,
      revelationPlace: 'مدنية',
    ),
    Surah(
      number: 3,
      name: 'آل عمران',
      englishName: 'Aal-E-Imran',
      versesCount: 200,
      revelationPlace: 'مدنية',
    ),
    Surah(
      number: 4,
      name: 'النساء',
      englishName: 'An-Nisa',
      versesCount: 176,
      revelationPlace: 'مدنية',
    ),
    Surah(
      number: 5,
      name: 'المائدة',
      englishName: 'Al-Maidah',
      versesCount: 120,
      revelationPlace: 'مدنية',
    ),
    Surah(
      number: 6,
      name: 'الأنعام',
      englishName: 'Al-Anam',
      versesCount: 165,
      revelationPlace: 'مكية',
    ),
    Surah(
      number: 7,
      name: 'الأعراف',
      englishName: 'Al-Araf',
      versesCount: 206,
      revelationPlace: 'مكية',
    ),
  ];
}
