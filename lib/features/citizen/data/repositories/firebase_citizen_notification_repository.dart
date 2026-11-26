import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/entities/citizen_notification.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/citizen_notification_repository.dart';

class FirebaseCitizenNotificationRepository
    implements CitizenNotificationRepository {
  DocumentReference<Map<String, dynamic>> _user(String userId) =>
      FirebaseFirestore.instance.collection('users').doc(userId);

  DocumentReference<Map<String, dynamic>> _preferences(String userId) =>
      _user(userId).collection('settings').doc('notifications');

  CollectionReference<Map<String, dynamic>> _inbox(String userId) =>
      _user(userId).collection('notifications');

  @override
  Future<CitizenNotificationPreferences> getPreferences(String userId) async {
    final data = (await _preferences(userId).get()).data();
    return CitizenNotificationPreferences(
      reportUpdates: data?['reportUpdates'] as bool? ?? true,
      nearbyTruck: data?['nearbyTruck'] as bool? ?? true,
      campaigns: data?['campaigns'] as bool? ?? false,
    );
  }

  @override
  Future<void> savePreferences(
    String userId,
    CitizenNotificationPreferences preferences,
  ) {
    return _preferences(userId).set({
      'reportUpdates': preferences.reportUpdates,
      'nearbyTruck': preferences.nearbyTruck,
      'campaigns': preferences.campaigns,
    }, SetOptions(merge: true));
  }

  @override
  Stream<List<CitizenNotification>> watchInbox(String userId, int limit) {
    return _inbox(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_decode).toList(growable: false));
  }

  @override
  Stream<int> watchUnreadCount(String userId, {required int limit}) {
    if (Firebase.apps.isEmpty) return Stream.value(0);
    return _inbox(userId)
        .where('readAt', isNull: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.size)
        .distinct();
  }

  @override
  Future<void> markRead(String userId, String notificationId) {
    return _inbox(
      userId,
    ).doc(notificationId).update({'readAt': FieldValue.serverTimestamp()});
  }

  CitizenNotification _decode(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return CitizenNotification(
      id: doc.id,
      reportId: data['reportId'] as String,
      reportNumber: data['reportNumber'] as String,
      status: ReportStatus.fromString(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['readAt'] != null,
    );
  }
}
