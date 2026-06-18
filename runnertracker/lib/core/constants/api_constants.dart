class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = 'http://10.0.2.2:8081/api/v1';
  static const String iosSimulatorBaseUrl = 'http://localhost:8081/api/v1';
  static const String productionBaseUrl = 'https://your-domain.com/api/v1';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/users/me';

  static const String runs = '/runs';
  static const String leaderboard = '/leaderboard';
  static const String events = '/events';
  static const String orders = '/orders';
}
