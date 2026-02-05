import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const int preResetAlarmId = 1;
  static const int resetAlarmId = 2;
  static const int deadlineReminderId = 3;
  static const int dailyKickstartId = 4;

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
    // Windows requires specific settings with appName, appUserModelId, and guid
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Claude Usage Alarm',
      appUserModelId: 'Com.ClaudeRefresher.ClaudeUsageAlarm',
      // Generate your own GUID at https://www.guidgenerator.com/ for production
      guid: 'a8c22b55-049e-422f-b30f-863694de08c8',
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );
    // FIX: Use named parameter 'settings:' instead of positional argument
    await _notifications.initialize(settings: initSettings);
  }

  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    return true;
  }

  Future<void> scheduleSmartNotifications({
    required DateTime startTime,
    int preResetMinutes = 5,
    int postResetMinutes = 5,
    int? deadlineHour,
    int deadlineMinutesBefore = 10,
  }) async {
    await cancelAllUsageNotifications();
    final resetTime = startTime.add(const Duration(hours: 5));
    final now = DateTime.now();

    final preResetTime = resetTime.subtract(Duration(minutes: preResetMinutes));
    if (preResetTime.isAfter(now)) {
      await _scheduleNotification(
        id: preResetAlarmId,
        time: preResetTime,
        title: '⏰ Claude Reset in $preResetMinutes minutes!',
        body: 'Your usage window resets at ${_formatTime(resetTime)}',
      );
    }

    final postResetTime = resetTime.add(Duration(minutes: postResetMinutes));
    if (postResetTime.isAfter(now)) {
      await _scheduleNotification(
        id: resetAlarmId,
        time: postResetTime,
        title: '🎉 Claude Window Reset!',
        body: 'Your 5-hour usage window has been refreshed!',
      );
    }

    if (deadlineHour != null) {
      var deadline = DateTime(now.year, now.month, now.day, deadlineHour);
      if (deadline.isBefore(now)) deadline = deadline.add(const Duration(days: 1));
      if (resetTime.isBefore(deadline)) {
        final reminderTime = deadline.subtract(Duration(minutes: deadlineMinutesBefore));
        if (reminderTime.isAfter(now) && reminderTime.isAfter(resetTime)) {
          await _scheduleNotification(
            id: deadlineReminderId,
            time: reminderTime,
            title: '📢 Use Claude before ${_formatTime(deadline)}!',
            body: 'Don\'t forget to use Claude before your deadline!',
          );
        }
      }
    }
  }

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _scheduleNotification({
    required int id,
    required DateTime time,
    required String title,
    required String body,
  }) async {
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      // FIX: Use named parameters for zonedSchedule
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(time, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('[Notification] Scheduled "$title" for $time');
    } catch (e) {
      print('[Notification] Error: $e');
    }
  }

  Future<void> scheduleDailyKickstart(int hour, int minute) async {
    try {
      // FIX: Use named parameter for cancel
      await _notifications.cancel(id: dailyKickstartId);
      var scheduledDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
      if (scheduledDate.isBefore(DateTime.now())) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      // FIX: Use named parameters for zonedSchedule
      await _notifications.zonedSchedule(
        id: dailyKickstartId,
        title: '☀️ Good Morning!',
        body: 'Start using Claude now!',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('[Notification] Error: $e');
    }
  }

  Future<void> cancelDailyKickstart() async {
    try {
      // FIX: Use named parameter for cancel
      await _notifications.cancel(id: dailyKickstartId);
    } catch (e) {
      // Silently handle
    }
  }

  Future<void> cancelAllUsageNotifications() async {
    try {
      // FIX: Use named parameters for cancel
      await _notifications.cancel(id: preResetAlarmId);
      await _notifications.cancel(id: resetAlarmId);
      await _notifications.cancel(id: deadlineReminderId);
    } catch (e) {
      // Silently handle
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      // Silently handle
    }
  }

  Future<void> showTestNotification() async {
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      // FIX: Use named parameters for show
      await _notifications.show(
        id: 0,
        title: 'Test Notification ✅',
        body: 'Notifications are working!',
        notificationDetails: details,
      );
    } catch (e) {
      print('[Notification] Error: $e');
    }
  }
}