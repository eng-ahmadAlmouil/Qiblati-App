import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ayah.dart';
import '../domain/surah.dart';

class QuranReaderRepository {
  const QuranReaderRepository();

  static const _lastSurahKey = 'quran_last_surah';
  static const _lastAyahKey = 'quran_last_ayah';
  static const _readAyahsKey = 'quran_read_ayahs';
  static const _completedSurahsKey = 'quran_completed_surahs';

  List<Ayah> getAyahs(Surah surah) {
    if (surah.number == 1) {
      return const [
        Ayah(number: 1, text: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ'),
        Ayah(number: 2, text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ'),
        Ayah(number: 3, text: 'الرَّحْمَنِ الرَّحِيمِ'),
        Ayah(number: 4, text: 'مَالِكِ يَوْمِ الدِّينِ'),
        Ayah(number: 5, text: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ'),
        Ayah(number: 6, text: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ'),
        Ayah(
          number: 7,
          text:
              'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ '
              'الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
        ),
      ];
    }

    return const [
      Ayah(number: 1, text: 'الم'),
      Ayah(
        number: 2,
        text: 'ذَٰلِكَ الْكِتَابُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى لِّلْمُتَّقِينَ',
      ),
      Ayah(
        number: 3,
        text:
            'الَّذِينَ يُؤْمِنُونَ بِالْغَيْبِ وَيُقِيمُونَ '
            'الصَّلَاةَ وَمِمَّا رَزَقْنَاهُمْ يُنفِقُونَ',
      ),
      Ayah(
        number: 4,
        text:
            'وَالَّذِينَ يُؤْمِنُونَ بِمَا أُنزِلَ إِلَيْكَ '
            'وَمَا أُنزِلَ مِن قَبْلِكَ وَبِالْآخِرَةِ هُمْ يُوقِنُونَ',
      ),
      Ayah(
        number: 5,
        text:
            'أُولَٰئِكَ عَلَىٰ هُدًى مِّن رَّبِّهِمْ ۖ '
            'وَأُولَٰئِكَ هُمُ الْمُفْلِحُونَ',
      ),
    ];
  }

  Future<void> saveLastRead({
    required Surah surah,
    required int ayahNumber,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_lastSurahKey, surah.number);
    await preferences.setInt(_lastAyahKey, ayahNumber);
    await markAyahRead(surahNumber: surah.number, ayahNumber: ayahNumber);
  }

  Future<void> markAyahRead({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final read = preferences.getStringList(_readAyahsKey) ?? <String>[];
    final key = '$surahNumber:$ayahNumber';
    if (!read.contains(key)) {
      await preferences.setStringList(_readAyahsKey, [...read, key]);
    }
  }

  Future<int> getReadAyahsCount() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_readAyahsKey) ?? <String>[]).length;
  }

  Future<void> markSurahCompleted(int surahNumber) async {
    final preferences = await SharedPreferences.getInstance();
    final completed =
        preferences.getStringList(_completedSurahsKey) ?? <String>[];
    final value = '$surahNumber';
    if (!completed.contains(value)) {
      await preferences.setStringList(_completedSurahsKey, [
        ...completed,
        value,
      ]);
    }
  }

  Future<int> getCompletedSurahCount() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_completedSurahsKey) ?? <String>[])
        .length;
  }

  Future<Set<int>> getCompletedSurahs() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_completedSurahsKey) ?? <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  Future<void> resetProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_completedSurahsKey);
    await preferences.remove(_readAyahsKey);
    await preferences.remove(_lastSurahKey);
    await preferences.remove(_lastAyahKey);
  }

  Future<({int? surahNumber, int? ayahNumber})> getLastRead() async {
    final preferences = await SharedPreferences.getInstance();
    return (
      surahNumber: preferences.getInt(_lastSurahKey),
      ayahNumber: preferences.getInt(_lastAyahKey),
    );
  }
}
