import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class CitizenPushService {
  static const enabled = bool.fromEnvironment(
    'ECOROUTE_PUSH_ENABLED',
    defaultValue: true,
  );

  static bool get isSupported =>
      enabled && !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      Firebase.apps.isNotEmpty;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  DocumentReference<Map<String, dynamic>> _device(String token) =>
      FirebaseFirestore.instance.collection('citizenPushDevices').doc(token);

  Stream<String> get tokenChanges => _messaging.onTokenRefresh;

  Future<bool> sync(String userId, {bool requestPermission = false}) async {
    if (FirebaseAuth.instance.currentUser?.uid != userId) return false;
    final settings = requestPermission
        ? await _messaging.requestPermission()
        : await _messaging.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return false;
    }
    final token = await _messaging.getToken();
    if (token == null) return false;
    return registerToken(userId, token);
  }

  Future<bool> registerToken(String userId, String token) async {
    if (FirebaseAuth.instance.currentUser?.uid != userId) return false;
    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized ||
        FirebaseAuth.instance.currentUser?.uid != userId) {
      return false;
    }
    if (token.contains('/') || token.length > 1024 || token.length < 20) return false;
    await _device(token).set({
      'uid': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return FirebaseAuth.instance.currentUser?.uid == userId;
  }

  Future<void> revoke(String userId) async {
    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;
    final token = await _messaging.getToken();
    if (token == null || FirebaseAuth.instance.currentUser?.uid != userId) {
      return;
    }
    try {
      if (!token.contains('/')) {
        await _device(token).delete().timeout(const Duration(seconds: 3));
      }
    } finally {
      if (FirebaseAuth.instance.currentUser?.uid == userId) {
        await _messaging.deleteToken();
      }
    }
  }
}
