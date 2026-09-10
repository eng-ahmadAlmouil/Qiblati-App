import 'package:flutter/foundation.dart';

import '../data/quran_api_repository.dart';
import '../domain/surah.dart';

enum QuranStatus { loading, ready, error }

class QuranController extends ChangeNotifier {
  QuranController({QuranApiRepository? repository})
    : _repository = repository ?? QuranApiRepository();

  final QuranApiRepository _repository;
  QuranStatus _status = QuranStatus.loading;
  List<Surah> _surahs = const [];
  String? _errorMessage;

  QuranStatus get status => _status;
  List<Surah> get surahs => _surahs;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = QuranStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _surahs = await _repository.getSurahs();
      _status = QuranStatus.ready;
    } on QuranApiException catch (error) {
      _status = QuranStatus.error;
      _errorMessage = error.message;
    } on FormatException {
      _status = QuranStatus.error;
      _errorMessage = 'بيانات القرآن غير صالحة حالياً.';
    }
    notifyListeners();
  }
}
