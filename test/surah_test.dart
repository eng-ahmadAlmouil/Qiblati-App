import 'package:flutter_test/flutter_test.dart';

import 'package:qiblati/features/quran/data/surah_repository.dart';

void main() {
  test('provides an ordered Quran surah catalog', () {
    const repository = SurahRepository();
    final surahs = repository.getAll();

    expect(surahs.length, greaterThan(3));
    expect(surahs.first.name, 'الفاتحة');
    expect(surahs.first.number, 1);
    expect(surahs[1].number, 2);
  });
}
