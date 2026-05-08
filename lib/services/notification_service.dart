import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // Skip full initialization on web
    if (kIsWeb) {
      debugPrint('NotificationService: Skipping init on Web');
      _initialized = true;
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const LinuxInitializationSettings linuxSettings = 
    LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: linuxSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    _initialized = true;
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('Notification clicked: ${response.payload}');
  }

  /// Derives a start DateTime from a BookingModel's date + time string
  DateTime _parseBookingStart(BookingModel booking) {
    // sessionTime is "HH:MM:SS" or "HH:MM"
    final parts = booking.sessionTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(
      booking.sessionDate.year,
      booking.sessionDate.month,
      booking.sessionDate.day,
      hour,
      minute,
    );
  }

  Future<void> scheduleWorkoutNotifications(BookingModel booking) async {
    if (kIsWeb) {
      debugPrint(
          'NotificationService: Scheduled notifications not supported on Web');
      return;
    }

    try {
      final startTime = _parseBookingStart(booking);
      final endTime = startTime.add(Duration(minutes: booking.durationMinutes));

      if (startTime.isBefore(DateTime.now())) return; // Past booking

      // 1. Pre-workout notification: 1 hour before
      final preWorkoutTime = startTime.subtract(const Duration(hours: 1));
      if (preWorkoutTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: booking.id.hashCode,
          title: 'Upcoming Workout!',
          body:
              'Don\'t forget to stretch, pack your bags and maybe grab your dumbbells. Your session starts in 1 hour.',
          scheduledTime: preWorkoutTime,
          payload: 'booking_${booking.id}',
        );
      }

      // 2. Post-workout congratulations: right after session ends
      if (endTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: booking.id.hashCode + 1,
          title: 'Session Complete! 🎉',
          body:
              'Congratulations on crushing your workout! Great job today.',
          scheduledTime: endTime,
          payload: 'complete_${booking.id}',
        );
      }

      // 3. Review reminder: 1 hr after workout ends
      final reviewTime = endTime.add(const Duration(hours: 1));
      if (reviewTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: booking.id.hashCode + 2,
          title: 'How was your session?',
          body:
              'Please check your email to review your session with the trainer.',
          scheduledTime: reviewTime,
          payload: 'review_${booking.id}',
        );
        debugPrint(
            'NotificationService: Scheduled review reminder for $reviewTime');
      }
    } catch (e) {
      debugPrint('NotificationService: Error scheduling notifications: $e');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'spotter_workout_channel',
      'Workout Reminders',
      channelDescription:
          'Notifications for upcoming workouts and completions',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDateTime,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    debugPrint(
        'Scheduled notification ID:$id Title:"$title" DateTime:$tzDateTime');
  }

  /// Cancels all notifications for a specific booking
  Future<void> cancelWorkoutNotifications(String bookingId) async {
    if (kIsWeb) return;
    try {
      await _flutterLocalNotificationsPlugin.cancel(id: bookingId.hashCode);
      await _flutterLocalNotificationsPlugin.cancel(id: bookingId.hashCode + 1);
      await _flutterLocalNotificationsPlugin.cancel(id: bookingId.hashCode + 2);
      debugPrint('Cancelled scheduled notifications for booking $bookingId');
    } catch (e) {
      debugPrint('NotificationService: cancel error: $e');
    }
  }

  /// Send an email review (Placeholder for Zoho integration)
  Future<void> triggerEmailReview(
      String userEmail, String trainerName) async {
    debugPrint(
        'ZOHO INTEGRATION: Sending review email to $userEmail for session with $trainerName');
  }
}
