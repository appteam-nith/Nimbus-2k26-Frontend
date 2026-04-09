class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final String location;
  final String imageUrl;
  final int day;

  TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.location,
    required this.imageUrl,
    required this.day,
  });

  bool get isLive {
    final now = DateTime.now().toUtc();
    final diff = now.difference(startTime.toUtc()).inMinutes;
    // Event is live from exactly when it starts, up to 60 minutes
    return diff >= 0 && diff <= 60;
  }

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      location: json['location'],
      imageUrl: json['imageUrl'] ?? '',
      day: json['day'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'location': location,
      'imageUrl': imageUrl,
      'day': day,
    };
  }
}
