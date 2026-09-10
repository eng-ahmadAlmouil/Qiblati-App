import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:qiblati/features/quran/data/quran_api_repository.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this.body);

  final String body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      request: request,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses the trusted Quran Cloud surah response', () async {
    const response = '''
    {
      "code": 200,
      "status": "OK",
      "data": [{
        "number": 1,
        "name": "سُورَةُ ٱلْفَاتِحَةِ",
        "englishName": "Al-Faatiha",
        "revelationType": "Meccan",
        "numberOfAyahs": 7
      }]
    }
    ''';
    final repository = QuranApiRepository(
      client: _FakeClient(response),
      useCache: false,
    );

    final surahs = await repository.getSurahs();

    expect(surahs.single.name, 'ٱلْفَاتِحَةِ');
    expect(surahs.single.versesCount, 7);
    expect(surahs.single.revelationPlace, 'مكية');
  });
}
