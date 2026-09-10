import 'dart:async';

import 'package:flutter/foundation.dart';

class SplashController extends ChangeNotifier {
  Timer? _timer;
  bool _isReady = false;

  bool get isReady => _isReady;

  void start() {
    _timer ??= Timer(const Duration(milliseconds: 1600), () {
      _isReady = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
