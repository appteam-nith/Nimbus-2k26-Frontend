import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../models/timeline_event.dart';
import '../services/timeline_api.dart';

class TimelineController extends ChangeNotifier {
  final TimelineApi _api = TimelineApi();

  final List<TimelineEvent> _allEvents = [];
  Timer? _timer;

  bool _isLoading = false;
  String? _error;

  int _selectedDay = 1;

  TimelineController() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_allEvents.isNotEmpty) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedDay => _selectedDay;

  List<TimelineEvent> get events {
    return _allEvents.where((e) => e.day == _selectedDay).toList();
  }

  List<TimelineEvent> get allEvents => List.unmodifiable(_allEvents);

  List<TimelineEvent> get upcomingEvents {
    final sorted = List<TimelineEvent>.from(_allEvents)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return sorted;
  }

  Future<void> loadTimeline() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.fetchTimeline();
      _allEvents
        ..clear()
        ..addAll(result);

      // Schedule notifications for every cached event safely 
      for (final event in _allEvents) {
         try {
           await LocalNotificationService.instance.scheduleEventNotifications(event);
         } catch (_) {}
      }

      // Auto-select Day based on current events
      final liveEvent = _allEvents.cast<TimelineEvent?>().firstWhere(
        (e) => e != null && e.isLive, 
        orElse: () => null
      );
      if (liveEvent != null) {
        _selectedDay = liveEvent.day;
      }
    } catch (e) {
      _error = 'Failed to load timeline';
    }

    _isLoading = false;
    notifyListeners();
  }

  void changeDay(int day) {
    if (day == _selectedDay) return;
    _selectedDay = day;
    notifyListeners();
  }
}
