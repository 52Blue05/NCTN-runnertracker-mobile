import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';
import '../model/event_model.dart';
import '../service/event_service.dart';

final eventServiceProvider = Provider<EventService>((ref) {
  return EventService(apiClient: ref.watch(apiClientProvider));
});

final eventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final service = ref.watch(eventServiceProvider);
  return await service.getEvents(filter: 'upcoming');
});
