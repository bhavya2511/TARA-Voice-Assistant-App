// lib/services/reminder_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class ReminderService {
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  ReminderService();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotificationsPlugin.initialize(initSettings);
  }

  Future<void> scheduleDailyMedicineReminders({
    List<TimeOfDaySpec>? times,
  }) async {
    final defaultTimes = [
      TimeOfDaySpec(hour: 9, minute: 0),
      TimeOfDaySpec(hour: 14, minute: 0),
      TimeOfDaySpec(hour: 20, minute: 0),
    ];
    final scheduleTimes = times ?? defaultTimes;

    await cancelAllReminders();

    for (int i = 0; i < scheduleTimes.length; i++) {
      final t = scheduleTimes[i];
      await _scheduleDaily(i + 1, t.hour, t.minute, 'Medicine time', 'Please take your medicine after your meal');
    }
  }

  Future<void> _scheduleDaily(int id, int hour, int minute, String title, String body) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    await _localNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails('tara_reminders', 'TARA reminders', channelDescription: 'Medicine reminders'),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAllReminders() async {
    await _localNotificationsPlugin.cancelAll();
  }
}

class TimeOfDaySpec {
  final int hour;
  final int minute;
  TimeOfDaySpec({required this.hour, required this.minute});
}
