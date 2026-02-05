import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int preResetAlarmId = 1;
  static const int resetAlarmId = 2;
  static const int deadlineReminderId = 3;
  static const int dailyKickstartId = 4;

  // Channel info
  static const String channelId = 'claude_usage_alarm';
  static const String channelName = 'Claude Usage Alerts';
  static const String channelDescription = 'Notifications for Claude usage limits';

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(initSettings);
  }

  Future<bool> requestPermissions() async {
    // Android 13+ requires notification permission
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS permissions
    final ios = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return true;
  }

  /// Schedule smart notifications based on window start time
  Future<void> scheduleSmartNotifications({
    required DateTime startTime,
    int preResetMinutes = 5,
    int postResetMinutes = 5,
    int? deadlineHour,
    int deadlineMinutesBefore = 10,
  }) async {
    // Cancel existing notifications first
    await cancelAllUsageNotifications();

    final resetTime = startTime.add(const Duration(hours: 5));
    final now = DateTime.now();

    // 1. Pre-reset alert (X minutes before reset)
    final preResetTime = resetTime.subtract(Duration(minutes: preResetMinutes));
    if (preResetTime.isAfter(now)) {
      await _scheduleNotification(
        id: preResetAlarmId,
        time: preResetTime,
        title: '⏰ Claude Reset in $preResetMinutes minutes!',
        body: 'Your usage window resets at ${_formatTime(resetTime)}',
      );
    }

    // 2. Post-reset alert (X minutes after reset)
    final postResetTime = resetTime.add(Duration(minutes: postResetMinutes));
    if (postResetTime.isAfter(now)) {
      await _scheduleNotification(
        id: resetAlarmId,
        time: postResetTime,
        title: '🎉 Claude Window Reset!',
        body: 'Your 5-hour usage window has been refreshed. Time to use Claude!',
      );
    }

    // 3. Deadline reminder (if enabled and applicable)
    if (deadlineHour != null) {
      final todayDeadline = DateTime(now.year, now.month, now.day, deadlineHour);
      var deadline = todayDeadline;
      if (deadline.isBefore(now)) {
        deadline = deadline.add(const Duration(days: 1));
      }

      // Only schedule if reset happens before deadline
      if (resetTime.isBefore(deadline)) {
        final reminderTime = deadline.subtract(Duration(minutes: deadlineMinutesBefore));
        if (reminderTime.isAfter(now) && reminderTime.isAfter(resetTime)) {
          await _scheduleNotification(
            id: deadlineReminderId,
            time: reminderTime,
            title: '📢 Use Claude before ${_formatTime(deadline)}!',
            body: 'Your window has reset. Don\'t forget to use Claude before your deadline!',
          );
        }
      }
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _scheduleNotification({
    required int id,
    required DateTime time,
    required String title,
    required String body,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(time, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('[Notification] Scheduled "$title" for $time');
    } catch (e) {
      print('[Notification] Error scheduling "$title": $e');
    }
  }

  /// Schedule daily kickstart notification
  Future<void> scheduleDailyKickstart(int hour, int minute) async {
    try {
      await _notifications.cancel(dailyKickstartId);

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        dailyKickstartId,
        '☀️ Good Morning!',
        'Start using Claude now to get your window reset by ${_formatTime(scheduledDate.add(const Duration(hours: 5)))}',
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print('[Notification] Scheduled daily kickstart for $hour:$minute');
    } catch (e) {
      print('[Notification] Error scheduling daily kickstart: $e');
    }
  }

  Future<void> cancelDailyKickstart() async {
    try {
      await _notifications.cancel(dailyKickstartId);
    } catch (e) {
      print('[Notification] Error cancelling daily kickstart: $e');
    }
  }

  Future<void> cancelAllUsageNotifications() async {
    try {
      await _notifications.cancel(preResetAlarmId);
      await _notifications.cancel(resetAlarmId);
      await _notifications.cancel(deadlineReminderId);
    } catch (e) {
      print('[Notification] Error cancelling usage notifications: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('[Notification] Error cancelling all: $e');
    }
  }

  Future<void> showTestNotification() async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        0,
        'Test Notification ✅',
        'Notifications are working!',
        details,
      );
    } catch (e) {
      print('[Notification] Error showing test notification: $e');
    }
  }
}
