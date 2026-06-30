class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = 'http://192.168.10.10:8081/api/v1';
  static const String iosSimulatorBaseUrl = 'http://localhost:8081/api/v1';
  static const String productionBaseUrl = 'https://your-domain.com/api/v1';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/users/me';

  static const String runs = '/runs';
  static const String leaderboard = '/leaderboard';
  static const String events = '/events';
  static const String orders = '/orders';

  // ── Goong Maps ──────────────────────────────────────────────
  // Maptiles key: dùng để hiển thị bản đồ (lấy từ https://account.goong.io)
  static const String goongMapKey = 'G4k6mKr143bFQxkNhPKrCtsUJibuvJ78CKBtqsga';

  // API key: dùng cho Geocoding, Directions, Autocomplete (nếu cần)
  static const String goongApiKey = '8oGIzTGkN4Mh9vcsBsR51MzRNqiNxsqwjUuws6r7';

  // Style URL của Goong (dùng với MapLibre)
  static String get goongStyleUrl =>
      'https://tiles.goong.io/assets/goong_map_web.json?api_key=$goongMapKey';
}
