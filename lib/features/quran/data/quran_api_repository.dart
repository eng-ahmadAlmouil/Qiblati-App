import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ayah.dart';
import '../domain/surah.dart';

class QuranApiException implements Exception {
  const QuranApiException(this.message);

  final String message;
}

class QuranApiRepository {
  QuranApiRepository({http.Client? client, bool useCache = true})
    : _client = client ?? http.Client(),
      _useCache = useCache;

  static const _baseUrl = 'api.alquran.cloud';
  static const _edition = 'quran-uthmani';
  static const _surahsCacheKey = 'quran_surahs_cache';
  static const _ayahsCachePrefix = 'quran_ayahs_';

  final http.Client _client;
  final bool _useCache;

  Future<List<Surah>> getSurahs({bool refresh = false}) async {
    final cached = _useCache ? await _readSurahsCache() : null;
    if (!refresh && cached != null && cached.isNotEmpty) return cached;
    try {
      final response = await _client
          .get(Uri.https(_baseUrl, '/v1/surah'))
          .timeout(const Duration(seconds: 12));
      final data = _parseDataList(response);
      final surahs = data.map(Surah.fromJson).toList();
      if (_useCache) await _writeSurahsCache(surahs);
      return surahs;
    } on Exception catch (error) {
      if (cached != null && cached.isNotEmpty) return cached;
      if (error is QuranApiException) rethrow;
      throw const QuranApiException('تعذر تحميل قائمة السور من المصدر.');
    }
  }

  Future<List<Ayah>> getAyahs(Surah surah, {bool refresh = false}) async {
    final cached = _useCache ? await _readAyahCache(surah.number) : null;
    final cacheHasPages =
        cached != null &&
        cached.isNotEmpty &&
        cached.every((ayah) => ayah.page != null);
    if (!refresh && cacheHasPages) return cached;
    try {
      final response = await _client
          .get(Uri.https(_baseUrl, '/v1/surah/${surah.number}/$_edition'))
          .timeout(const Duration(seconds: 12));
      final data = _parseData(response);
      if (data is! Map<String, dynamic> || data['ayahs'] is! List<dynamic>) {
        throw const QuranApiException('وصلت بيانات الآيات بصيغة غير صالحة.');
      }
      final ayahs = (data['ayahs'] as List<dynamic>)
          .map((ayah) {
            if (ayah is! Map<String, dynamic>) {
              throw const FormatException('بيانات الآية غير صالحة.');
            }
            return Ayah.fromJson(ayah);
          })
          .toList();
      if (_useCache) await _writeAyahCache(surah.number, ayahs);
      return ayahs;
    } on Exception catch (error) {
      if (cached != null && cached.isNotEmpty) return cached;
      if (error is QuranApiException) rethrow;
      throw const QuranApiException('تعذر تحميل آيات السورة من المصدر.');
    }
  }

  List<Map<String, dynamic>> _parseDataList(http.Response response) {
    final data = _parseData(response);
    throwIfInvalid(data);
    return (data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  dynamic _parseData(http.Response response) {
    if (response.statusCode != 200) {
      throw const QuranApiException('تعذر الاتصال بمصدر القرآن الموثوق.');
    }
    late final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const QuranApiException('وصلت بيانات القرآن بصيغة غير صالحة.');
    }
    if (decoded is! Map<String, dynamic> || decoded['data'] == null) {
      throw const QuranApiException('وصلت بيانات القرآن بصيغة غير صالحة.');
    }
    return decoded['data'];
  }

  void throwIfInvalid(Object? data) {
    if (data is! List<dynamic>) {
      throw const QuranApiException('قائمة السور غير صالحة.');
    }
  }

  Future<List<Surah>?> _readSurahsCache() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_surahsCacheKey);
    if (value == null) return null;
    final list = jsonDecode(value) as List<dynamic>;
    return list
        .map((item) => Surah.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeSurahsCache(List<Surah> surahs) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _surahsCacheKey,
      jsonEncode(surahs.map((surah) => surah.toJson()).toList()),
    );
  }

  Future<List<Ayah>?> _readAyahCache(int surahNumber) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString('$_ayahsCachePrefix$surahNumber');
      if (value == null) return null;
      final list = jsonDecode(value);
      if (list is! List) return null;
      return list
          .map((item) => Ayah.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> _writeAyahCache(int surahNumber, List<Ayah> ayahs) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_ayahsCachePrefix$surahNumber',
      jsonEncode(
        ayahs
            .map(
              (ayah) => {
                'numberInSurah': ayah.number,
                'text': ayah.text,
                if (ayah.page != null) 'page': ayah.page,
              },
            )
            .toList(),
      ),
    );
  }
}
