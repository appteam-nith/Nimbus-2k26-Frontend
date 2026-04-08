class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final String location;
  final String imageUrl;
  final bool isLive;
  final int day;

  TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.location,
    required this.imageUrl,
    required this.isLive,
    required this.day,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      location: json['location'],
      imageUrl: json['imageUrl'] ?? '',
      isLive: json['isLive'],
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
      'isLive': isLive,
      'day': day,
    };
  }
}
