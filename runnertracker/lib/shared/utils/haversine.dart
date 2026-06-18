import 'dart:math';

class Haversine {
  const Haversine._();

  static const double _earthRadiusMeters = 6371000;

  static double distanceInMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final deltaLatitude = _toRadians(endLatitude - startLatitude);
    final deltaLongitude = _toRadians(endLongitude - startLongitude);
    final startLatRadians = _toRadians(startLatitude);
    final endLatRadians = _toRadians(endLatitude);

    final a =
        pow(sin(deltaLatitude / 2), 2) +
        cos(startLatRadians) *
            cos(endLatRadians) *
            pow(sin(deltaLongitude / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
