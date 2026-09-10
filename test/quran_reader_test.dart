import 'package:flutter_test/flutter_test.dart';

import 'package:qiblati/features/quran/data/quran_reader_repository.dart';
import 'package:qiblati/features/quran/data/surah_repository.dart';

void main() {
  test('loads Arabic ayahs for Al-Fatihah', () {
    const surahRepository = SurahRepository();
    const readerRepository = QuranReaderRepository();
    final surah = surahRepository.getAll().first;
    final ayahs = readerRepository.getAyahs(surah);

    expect(ayahs.length, 7);
    expect(ayahs.first.text, contains('بِسْمِ اللَّهِ'));
    expect(ayahs.last.number, 7);
  });
}
