// lib/services/notification_service.dart
// Notifications handled via in-app reminders only (no native plugin)
class NotificationService {
  static Future<void> initialize() async {}
  static Future<void> scheduleNotification({required int id, required String title, required String body, required DateTime scheduledDate}) async {}
  static Future<void> sendTestNotification() async {}
  static Future<void> showTimerNotification(String chapterName) async {}
  static Future<void> cancelTimerNotification() async {}
  static Future<void> scheduleDnd(String startTime, String endTime) async {}
  static Future<void> cancelNotification(int id) async {}
  static Future<void> cancelDnd() async {}
  static Future<void> cancelAll() async {}
  static Future<void> requestExactAlarmPermission() async {}
}
