import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../model/leaderboard_entry_model.dart';

class LeaderboardService {
  LeaderboardService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<LeaderboardEntryModel>> getLeaderboard(String period) async {
    final response = await apiClient.get(
      ApiConstants.leaderboard,
      queryParameters: {'period': period},
    );

    final data = response.data['data'] as List<dynamic>;
    return data.map((item) => LeaderboardEntryModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
