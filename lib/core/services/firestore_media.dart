import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Convierte referencias persistidas de Firestore en ubicaciones para la UI.
abstract final class FirestoreMedia {
  static const _prefix = 'firestore:/';

  static String location(String path) => '$_prefix$path';

  static String? path(String location) =>
      location.startsWith(_prefix) ? location.substring(_prefix.length) : null;

  static String? readLocation(Object? path, Object? legacyUrl) {
    if (path is String && path.isNotEmpty) return location(path);
    return legacyUrl is String && legacyUrl.trim().isNotEmpty
        ? legacyUrl
        : null;
  }

  static Map<String, Object> document(Uint8List bytes) => {
    'data': Blob(bytes),
    'contentType': 'image/jpeg',
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
