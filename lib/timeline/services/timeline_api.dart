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
    final extra = _parseExtraDetails(e['extra_details']);
    final eventTimeRaw = e['event_time'] as String? ?? '';
    final startTime = DateTime.parse(eventTimeRaw);

    return TimelineEvent(
      id: e['event_id'].toString(),
      title: e['event_name'] as String? ?? 'Event',
      description: extra['description'] as String? ?? '',
      startTime: startTime,
      location: e['venue'] as String? ?? '',
      imageUrl: e['image_url'] as String? ?? '',
      // day can arrive as int/string in extra_details.day.
      // Fallback: infer from event date (10/11/12 Apr -> 1/2/3).
      day: _resolveDay(extra['day'], startTime),
    );
  }

  Map<String, dynamic> _parseExtraDetails(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return const {};
  }

  int _resolveDay(dynamic rawDay, DateTime startTime) {
    int? parsed;
    if (rawDay is num) {
      parsed = rawDay.toInt();
    } else if (rawDay is String) {
      parsed = int.tryParse(rawDay.trim());
    }

    if (parsed != null && parsed >= 1 && parsed <= 3) return parsed;

    final ist = startTime.toUtc().add(const Duration(hours: 5, minutes: 30));
    switch (ist.day) {
      case 10:
        return 1;
      case 11:
        return 2;
      case 12:
        return 3;
      default:
        return 1;
    }
  }
}
