import '../config/api_endpoints.dart';
import '../models/event.dart';
import 'api_service.dart';

class EventService {
  final ApiService _apiService;

  EventService({required ApiService apiService}) : _apiService = apiService;

  // Fetch all companies from API and cache them
  Future<List<Event>> getAllEvents() async {
    try {
      final response = await _apiService.get(ApiEndpoints.events);
      if (response.isSuccess && response.data != null) {
        // The data is already parsed as a List<dynamic>
        final List<dynamic> eventsJson = response.data as List<dynamic>;
        List<Event> events =
            eventsJson
                .map((json) => Event.fromJson(json as Map<String, dynamic>))
                .toList();
        print(events);
        return events;
      } else {
        throw Exception('Failed to load companies: ${response.error}');
      }
    } catch (e) {
      throw Exception('Error fetching companies: $e');
    }
  }
}
