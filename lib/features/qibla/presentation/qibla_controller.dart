import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/qibla_calculator.dart';

enum QiblaStatus {
  idle,
  loading,
  ready,
  permissionDenied,
  locationDisabled,
  sensorUnavailable,
  error,
}

class QiblaController extends ChangeNotifier {
  QiblaStatus _status = QiblaStatus.idle;
  double? _qiblaBearing;
  double? _deviceHeading;
  String? _errorMessage;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _disposed = false;
  bool _loadingLocation = false;

  QiblaStatus get status => _status;
  double? get qiblaBearing => _qiblaBearing;
  double? get deviceHeading => _deviceHeading;
  String? get errorMessage => _errorMessage;
  bool get locationEnabled => _status == QiblaStatus.ready;

  double? get relativeBearing {
    final qiblaBearing = _qiblaBearing;
    final deviceHeading = _deviceHeading;
    if (qiblaBearing == null || deviceHeading == null) return null;

    return QiblaCalculator.relativeBearing(
      qiblaBearing: qiblaBearing,
      deviceHeading: deviceHeading,
    );
  }

  Future<void> enableLocation() async {
    if (_disposed || _loadingLocation) return;
    _loadingLocation = true;
    _setStatus(QiblaStatus.loading);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setStatus(QiblaStatus.locationDisabled);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setStatus(QiblaStatus.permissionDenied);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (_disposed) return;
      _qiblaBearing = QiblaCalculator.bearingToKaaba(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      unawaited(_listenToCompass());
    } catch (error) {
      if (_disposed) return;
      _errorMessage = error.toString();
      _setStatus(QiblaStatus.error);
    } finally {
      _loadingLocation = false;
    }
  }

  Future<void> retryLocation() async {
    if (_disposed || _loadingLocation) return;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    if (permission == LocationPermission.denied) {
      _setStatus(QiblaStatus.permissionDenied);
      return;
    }
    await enableLocation();
  }

  Future<void> _listenToCompass() async {
    if (_disposed) return;
    final compassStream = FlutterCompass.events;
    if (compassStream == null) {
      _setStatus(QiblaStatus.sensorUnavailable);
      return;
    }

    await _compassSubscription?.cancel();
    if (_disposed) return;
    _compassSubscription = compassStream.listen(
      (event) {
        if (_disposed) return;
        final heading = event.heading;
        if (heading == null) {
          _setStatus(QiblaStatus.sensorUnavailable);
          return;
        }

        _deviceHeading = heading;
        _setStatus(QiblaStatus.ready);
      },
      onError: (_, _) {
        if (!_disposed) _setStatus(QiblaStatus.sensorUnavailable);
      },
    );
  }

  void _setStatus(QiblaStatus status) {
    if (_disposed) return;
    _status = status;
    notifyListeners();
  }

  Future<void> pauseCompass() async {
    await _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  void resumeCompass() {
    if (!_disposed && _qiblaBearing != null) {
      unawaited(_listenToCompass());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _compassSubscription?.cancel();
    super.dispose();
  }
}
