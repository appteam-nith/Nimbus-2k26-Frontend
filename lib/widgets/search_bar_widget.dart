import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../timeline/controller/timeline_controller.dart';
import '../timeline/models/timeline_event.dart';
import '../widgets/event_card.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      onTap: () {
        final events = context.read<TimelineController>().allEvents;
        showSearch(
          context: context,
          delegate: EventsSearchDelegate(events: events),
        );
      },
      decoration: InputDecoration(
        hintText: "Search events, workshops...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class EventsSearchDelegate extends SearchDelegate<TimelineEvent?> {
  final List<TimelineEvent> events;

  EventsSearchDelegate({required this.events});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(isSuggestions: true);

  String _formatTime(DateTime time) {
    final istTime = time.toUtc().add(const Duration(hours: 5, minutes: 30));
    final hour = istTime.hour % 12 == 0 ? 12 : istTime.hour % 12;
    final minute = istTime.minute.toString().padLeft(2, '0');
    final period = istTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period IST';
  }

  Widget _buildList({bool isSuggestions = false}) {
    if (query.isEmpty) {
      if (isSuggestions) return const SizedBox();
    }
    
    final q = query.toLowerCase();
    final results = events.where((e) => 
      e.title.toLowerCase().contains(q) || 
      e.description.toLowerCase().contains(q) || 
      e.location.toLowerCase().contains(q)
    ).toList();

    if (results.isEmpty) {
      return const Center(child: Text('No events found.'));
    }

    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final event = results[index];
        return EventCard(
          title: event.title,
          tag: event.isLive ? 'Live' : 'Event',
          time: _formatTime(event.startTime),
          location: event.location,
          image: event.imageUrl.isNotEmpty
              ? event.imageUrl
              : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400',
          primary: event.isLive,
        );
      },
    );
  }
}
