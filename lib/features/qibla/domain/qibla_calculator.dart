import 'dart:math' as math;

abstract final class QiblaCalculator {
  static const kaabaLatitude = 21.422487;
  static const kaabaLongitude = 39.826206;

  static double bearingToKaaba({
    required double latitude,
    required double longitude,
  }) {
    final currentLatitude = _toRadians(latitude);
    final kaabaLat = _toRadians(kaabaLatitude);
    final deltaLongitude = _toRadians(kaabaLongitude - longitude);

    final y = math.sin(deltaLongitude);
    final x =
        math.cos(currentLatitude) * math.sin(kaabaLat) -
        math.sin(currentLatitude) *
            math.cos(kaabaLat) *
            math.cos(deltaLongitude);

    return _normalizeDegrees(_toDegrees(math.atan2(y, x)));
  }

  static double relativeBearing({
    required double qiblaBearing,
    required double deviceHeading,
  }) {
    return _normalizeDegrees(qiblaBearing - deviceHeading);
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  static double _toDegrees(double radians) => radians * 180 / math.pi;

  static double _normalizeDegrees(double degrees) => (degrees + 360) % 360;
}
