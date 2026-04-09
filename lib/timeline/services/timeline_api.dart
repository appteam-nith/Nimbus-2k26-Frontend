import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/timeline_event.dart';

class TimelineApi {
  static const String _baseUrl =
      'https://nimbus-2k26-backend-olhw.onrender.com';

  Future<List<TimelineEvent>> fetchTimeline() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/events'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load events: ${response.statusCode}');
    }

    final body = jsonDecode(response.body);
    final List<dynamic> rawEvents = body['data'] ?? [];

    return rawEvents
        .map((e) => _mapToTimelineEvent(e as Map<String, dynamic>))
        .toList();
  }

  /// Maps a raw backend event JSON object to a [TimelineEvent].
  ///
  /// Backend Event fields:
  ///   event_id, event_name, venue, event_time (ISO8601), image_url, extra_details
  ///
  /// extra_details (JSON) stores optional { "description": "...", "day": 1|2|3 }
  /// that are set when creating events via POST /api/events.
  TimelineEvent _mapToTimelineEvent(Map<String, dynamic> e) {
    final extra = e['extra_details'] as Map<String, dynamic>? ?? {};

    return TimelineEvent(
      id: e['event_id'].toString(),
      title: e['event_name'] as String? ?? 'Event',
      description: extra['description'] as String? ?? '',
      startTime: DateTime.parse(e['event_time'] as String),
      location: e['venue'] as String? ?? '',
      imageUrl: e['image_url'] as String? ?? '',
      // day is stored in extra_details.day; defaults to 1 if not set
      day: (extra['day'] as num?)?.toInt() ?? 1,
    );
  }
}
