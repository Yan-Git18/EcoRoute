import '../entities/citizen_notification.dart';

abstract interface class CitizenNotificationRepository {
  Future<CitizenNotificationPreferences> getPreferences(String userId);
  Future<void> savePreferences(
    String userId,
    CitizenNotificationPreferences preferences,
  );
  Stream<List<CitizenNotification>> watchInbox(String userId, int limit);
  Stream<int> watchUnreadCount(String userId, {required int limit});
  Future<void> markRead(String userId, String notificationId);
}
