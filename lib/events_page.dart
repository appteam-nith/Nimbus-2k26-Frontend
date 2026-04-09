import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'timeline/controller/timeline_controller.dart';
import 'timeline/models/timeline_event.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int selectedCategory = 0;
  final categories = ['All', 'Workshops', 'Hackathons', 'Talks'];

  @override
  void initState() {
    super.initState();
    context.read<TimelineController>().loadTimeline();
  }

  String _formatDateTime(DateTime time) {
    final istTime = time.toUtc().add(const Duration(hours: 5, minutes: 30));
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][istTime.month - 1];
    final hour = istTime.hour % 12 == 0 ? 12 : istTime.hour % 12;
    final minute = istTime.minute.toString().padLeft(2, '0');
    final period = istTime.hour >= 12 ? 'PM' : 'AM';
    return '$month ${istTime.day} • $hour:$minute $period IST';
  }

  List<TimelineEvent> _filteredEvents(List<TimelineEvent> events) {
    if (selectedCategory == 0) return events;
    final filter = categories[selectedCategory].toLowerCase();
    return events.where((event) {
      return event.description.toLowerCase().contains(filter) ||
          event.title.toLowerCase().contains(filter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TimelineController>();
    final events = _filteredEvents(controller.allEvents);

    final children = <Widget>[
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "NIMBUS FEST '24",
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, size: 18),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const Text(
        'Events',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 45,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 10),
            Text(
              'Search workshops, talks...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final isSelected = selectedCategory == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xff3B82F6)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
    ];

    if (controller.error != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            controller.error!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    } else if (controller.isLoading && events.isEmpty) {
      children.add(
        const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (events.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No events found.'),
        ),
      );
    } else {
      children.addAll([
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(
                events.first.imageUrl.isNotEmpty &&
                        events.first.imageUrl.startsWith('http')
                    ? events.first.imageUrl
                    : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    events.first.isLive ? 'Live' : 'Featured',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateTime(events.first.startTime),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            events.first.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            events.first.location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ]);

      children.addAll(
        events.map((e) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    e.imageUrl.isNotEmpty && e.imageUrl.startsWith('http')
                        ? e.imageUrl
                        : 'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=400',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 18,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(e.startTime),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.location,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'View Details',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: children,
        ),
      ),
    );
  }
}
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: children,
        ),
      ),
    );
  }
}
