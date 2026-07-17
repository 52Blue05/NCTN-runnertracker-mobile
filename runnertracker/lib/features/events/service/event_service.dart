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

    final responseData = response.data['data'];

    // Backend trả về Page<EventResponse> (có 'content') hoặc List trực tiếp
    List<dynamic> items;
    if (responseData is Map<String, dynamic> && responseData.containsKey('content')) {
      items = responseData['content'] as List<dynamic>;
    } else if (responseData is List<dynamic>) {
      items = responseData;
    } else {
      items = [];
    }

    return items.map((item) => EventModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
