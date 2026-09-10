import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/tafsir_ayah.dart';

class TafsirException implements Exception {
  const TafsirException(this.message);

  final String message;
}

class TafsirRepository {
  TafsirRepository({http.Client? client})
    : _client = client ?? http.Client();

  static const _baseUrl = 'api.alquran.cloud';
  static const _edition = 'ar.muyassar';
  static const _cachePrefix = 'tafsir_muyassar_';

  final http.Client _client;

  Future<List<TafsirAyah>> getSurahTafsir(
    int surahNumber, {
    bool refresh = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final key = '$_cachePrefix$surahNumber';
    final cached = _readCache(preferences.getString(key));
    if (!refresh && cached != null && cached.isNotEmpty) return cached;

    try {
      final response = await _client
          .get(Uri.https(_baseUrl, '/v1/surah/$surahNumber/$_edition'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const TafsirException('تعذر الاتصال بمصدر التفسير.');
      }
      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      final ayahs = data is Map<String, dynamic> ? data['ayahs'] : null;
      if (ayahs is! List) {
        throw const TafsirException('وصلت بيانات التفسير بصيغة غير صالحة.');
      }
      final result = ayahs
          .map((item) => TafsirAyah.fromJson(item as Map<String, dynamic>))
          .toList();
      await preferences.setString(
        key,
        jsonEncode(
          result
              .map(
                (ayah) => {
                  'number': ayah.number,
                  'numberInSurah': ayah.numberInSurah,
                  'text': ayah.text,
                },
              )
              .toList(),
        ),
      );
      return result;
    } on TafsirException {
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    } on Exception {
      if (cached != null && cached.isNotEmpty) return cached;
      throw const TafsirException('تعذر تحميل التفسير حالياً.');
    }
  }

  List<TafsirAyah>? _readCache(String? value) {
    if (value == null) return null;
    final decoded = jsonDecode(value);
    if (decoded is! List) return null;
    return decoded
        .map((item) => TafsirAyah.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
