import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';
import '../../tracking/model/run_session_model.dart';
import '../../tracking/service/run_session_service.dart';

final historyServiceProvider = Provider<RunSessionService>((ref) {
  return RunSessionService(apiClient: ref.watch(apiClientProvider));
});

final historyProvider = FutureProvider<List<RunSessionModel>>((ref) async {
  final service = ref.watch(historyServiceProvider);
  return await service.getRunSessions(page: 0, size: 50); // Fetch top 50 for now
});
