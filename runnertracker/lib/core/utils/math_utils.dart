import 'dart:math' as math;

class MathUtils {
  static const double earthRadiusKm = 6371.0;

  /// Tính khoảng cách giữa 2 điểm (km) theo công thức Haversine
  static double haversineDistance(double lat1Deg, double lon1Deg, double lat2Deg, double lon2Deg) {
    final dLat = _toRadians(lat2Deg - lat1Deg);
    final dLon = _toRadians(lon2Deg - lon1Deg);

    final lat1 = _toRadians(lat1Deg);
    final lat2 = _toRadians(lat2Deg);

    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);

    final h = sinDLat * sinDLat +
        math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;

    final c = 2 * math.asin(math.sqrt(h));

    return earthRadiusKm * c;
  }

  static double _toRadians(double degree) {
    return degree * math.pi / 180.0;
  }

  /// Tính Pace (số phút để hoàn thành 1km)
  /// Trả về chuỗi format mm:ss (vd: 05:30)
  static String formatPace(Duration duration, double distanceKm) {
    if (distanceKm <= 0.01) return "--:--"; // Chưa đủ khoảng cách để tính pace
    
    // Tổng số phút đã chạy
    final totalMinutes = duration.inSeconds / 60.0;
    
    // Pace = Số phút / 1 km
    final paceDecimal = totalMinutes / distanceKm;
    
    if (paceDecimal > 60) return ">60:00"; // Chạy quá chậm hoặc lỗi GPS
    
    final paceMinutes = paceDecimal.floor();
    final paceSeconds = ((paceDecimal - paceMinutes) * 60).round();
    
    // Xử lý trường hợp làm tròn giây lên 60
    if (paceSeconds >= 60) {
      return '${(paceMinutes + 1).toString().padLeft(2, '0')}:00';
    }
    
    return '${paceMinutes.toString().padLeft(2, '0')}:${paceSeconds.toString().padLeft(2, '0')}';
  }
}
