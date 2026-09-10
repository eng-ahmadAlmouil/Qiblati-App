import 'package:flutter_test/flutter_test.dart';

import 'package:qiblati/features/qibla/domain/qibla_calculator.dart';

void main() {
  test('calculates the bearing from Madinah to the Kaaba', () {
    final bearing = QiblaCalculator.bearingToKaaba(
      latitude: 24.5247,
      longitude: 39.5692,
    );

    expect(bearing, closeTo(175.3, 0.5));
  });

  test('normalizes the relative bearing to a compass circle', () {
    final bearing = QiblaCalculator.relativeBearing(
      qiblaBearing: 10,
      deviceHeading: 350,
    );

    expect(bearing, closeTo(20, 0.001));
  });
}
