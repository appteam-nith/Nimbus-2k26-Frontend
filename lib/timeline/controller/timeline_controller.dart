import 'package:flutter/material.dart';
import '../models/timeline_event.dart';
import '../services/timeline_api.dart';

class TimelineController extends ChangeNotifier {
  final TimelineApi _api = TimelineApi();

  final List<TimelineEvent> _allEvents = [];

  bool _isLoading = false;
  String? _error;

  int _selectedDay = 1; // 1,2,3

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedDay => _selectedDay;

  // ✅ FIXED – use event.day
  List<TimelineEvent> get events {
    return _allEvents
        .where((e) => e.day == _selectedDay)
        .toList();
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
