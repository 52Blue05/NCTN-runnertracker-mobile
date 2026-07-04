import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../model/event_model.dart';

class EventService {
  EventService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<EventModel>> getEvents({String filter = 'upcoming'}) async {
    final response = await apiClient.get(
      ApiConstants.events,
      queryParameters: {'filter': filter},
    );

    final data = response.data['data'] as List<dynamic>;
    return data.map((item) => EventModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
