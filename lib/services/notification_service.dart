import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../timeline/models/timeline_event.dart';

class LocalNotificationService {
  static final LocalNotificationService instance = LocalNotificationService._internal();

  factory LocalNotificationService() => instance;

  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    var status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> scheduleEventNotifications(TimelineEvent event) async {
    if (!_initialized) await init();

    // Event ID must be a unique integer, so we take a hash code
    final int baseId = event.id.hashCode;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'timeline_events_channel',   // channel id
      'Event Alerts',              // channel name
      channelDescription: 'Notifications for upcoming events.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // 1. Notification exactly at start time
    if (event.startTime.isAfter(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: baseId, // Unique ID for exact start alert
        title: '${event.title} started',
        body: 'Head over to the venue to catch the action!',
        scheduledDate: tz.TZDateTime.from(event.startTime, tz.local),
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    // 2. Notification 5 minutes prior
    final DateTime fiveMinsPrior = event.startTime.subtract(const Duration(minutes: 5));
    if (fiveMinsPrior.isAfter(DateTime.now())) {
      // XOR the hash trick to avoid collision with base ID
      final int priorAlertId = baseId ^ 0x0F0F0F;
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: priorAlertId,
        title: '${event.title} is about to start',
        body: 'Starting in 5 minutes at ${event.location}.',
        scheduledDate: tz.TZDateTime.from(fiveMinsPrior, tz.local),
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }
}
