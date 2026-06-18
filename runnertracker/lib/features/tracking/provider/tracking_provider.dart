import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../service/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
