import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';
import '../model/leaderboard_entry_model.dart';
import '../service/leaderboard_service.dart';

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService(apiClient: ref.watch(apiClientProvider));
});

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntryModel>, String>((ref, period) async {
  final service = ref.watch(leaderboardServiceProvider);
  return await service.getLeaderboard(period);
});
