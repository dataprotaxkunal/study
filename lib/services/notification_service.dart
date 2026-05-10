// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (_) {},
    );

    final ap = _plugin.resolvePlatformSpecificImplementation
        AndroidFlutterLocalNotificationsPlugin>();

    await ap?.createNotificationChannel(const AndroidNotificationChannel(
      'study_reminders', 'Study Reminders',
      description: 'Study session notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ));

    await ap?.createNotificationChannel(const AndroidNotificationChannel(
      'study_timer', 'Study Timer',
      description: 'Active session',
      importance: Importance.low,
      playSound: false,
    ));

    await ap?.createNotificationChannel(const AndroidNotificationChannel(
      'dnd_control', 'Focus Mode',
      description: 'Focus reminders',
      importance: Importance.max,
      playSound: true,
    ));

    await ap?.requestPermission();
    _initialized = true;
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await initialize();
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'study_reminders', 'Study Reminders',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
      ),
    );
    try {
      await _plugin.zonedSchedule(
        id, title, body, tzDate, details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  static Future<void> sendTestNotification() async {
    await initialize();
    await _plugin.show(
      99999,
      '✅ Notifications Working!',
      'CMA Study Tracker notifications are active.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_reminders', 'Study Reminders',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }

  static Future<void> showTimerNotification(String chapterName) async {
    await initialize();
    await _plugin.show(
      88888,
      '⏱ Studying Now',
      'Session: $chapterName',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_timer', 'Study Timer',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          playSound: false,
        ),
      ),
    );
  }

  static Future<void> cancelTimerNotification() async {
    await _plugin.cancel(88888);
  }

  static Future<void> scheduleDnd(
      String startTime, String endTime) async {
    await initialize();
    await cancelDnd();
    final sp = startTime.split(':');
    final ep = endTime.split(':');
    final sH = int.tryParse(sp[0]) ?? 9;
    final sM = int.tryParse(sp.length > 1 ? sp[1] : '0') ?? 0;
    final eH = int.tryParse(ep[0]) ?? 18;
    final eM = int.tryParse(ep.length > 1 ? ep[1] : '0') ?? 0;
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final base = now.add(Duration(days: i));
      final startDt =
          DateTime(base.year, base.month, base.day, sH, sM);
      if (startDt.isAfter(now)) {
        await scheduleNotification(
          id: 90000 + i,
          title: '📵 Focus Mode ON',
          body: 'Enable Do Not Disturb — calls allowed',
          scheduledDate: startDt,
        );
      }
      final endDt =
          DateTime(base.year, base.month, base.day, eH, eM);
      if (endDt.isAfter(now)) {
        await scheduleNotification(
          id: 91000 + i,
          title: '🔔 Focus Mode OFF',
          body: 'Study session ended. Disable DND.',
          scheduledDate: endDt,
        );
      }
    }
  }

  static Future<void> cancelNotification(int id) async {
    for (int i = id * 1000; i < id * 1000 + 365; i++) {
      await _plugin.cancel(i);
    }
  }

  static Future<void> cancelDnd() async {
    for (int i = 0; i < 30; i++) {
      await _plugin.cancel(90000 + i);
      await _plugin.cancel(91000 + i);
    }
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();

  static Future<void> requestExactAlarmPermission() async {
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }
}
