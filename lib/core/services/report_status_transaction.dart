import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../errors/exceptions.dart';
import 'firestore_media.dart';

Future<({Map<String, dynamic> fields, bool changed})> writeReportStatus({
  required DocumentReference<Map<String, dynamic>> report,
  required Map<String, dynamic> changes,
  List<Uint8List> evidencePhotos = const [],
}) async {
  final firestore = report.firestore;
  final eventId = const Uuid().v4();

  Future<({Map<String, dynamic> fields, bool changed})> commit({
    required bool includeNotice,
  }) {
    return firestore.runTransaction((transaction) async {
      final current = (await transaction.get(report)).data();
      if (current == null) throw const ServerException(message: 'El reporte no existe.');
      final previousStatus = _status(current['status']);
      final status = changes['status'];
      final updates = {...changes, 'updatedAt': FieldValue.serverTimestamp()};

      if (evidencePhotos.isNotEmpty) {
        final media = report.collection('media');
        final evidence = List.generate(
          evidencePhotos.length,
          (index) => media.doc(index == 0 ? 'evidence' : 'evidence_$index'),
        );
        if (previousStatus == 'resolved' &&
            current['assignedStaffId'] == changes['assignedStaffId'] &&
            current['evidenceImagePath'] == evidence.first.path) {
          return (fields: current, changed: false);
        }
        updates['evidenceImagePath'] = evidence.first.path;
        if (evidence.length > 1) {
          updates['evidenceImagePaths'] = evidence.map((photo) => photo.path).toList();
        }
        for (var index = 0; index < evidence.length; index++) {
          transaction.set(evidence[index], FirestoreMedia.document(evidencePhotos[index]));
        }
      }
      final owner = current['citizenId'];
      if (previousStatus != status &&
          const {'assigned', 'in_progress', 'resolved'}.contains(status)) {
        updates['statusEventId'] = eventId;
        if (includeNotice && owner is String && owner.isNotEmpty) {
          final notice = firestore.collection('users').doc(owner)
              .collection('notifications').doc(eventId);
          transaction.set(notice, {
            'reportId': report.id,
            'reportNumber': current['reportNumber'] ?? report.id,
            'status': status,
            'createdAt': FieldValue.serverTimestamp(),
            'readAt': null,
            'pushPending': true,
          });
        }
      }
      transaction.update(report, updates);
      return (
        fields: {...current, ...updates, 'updatedAt': Timestamp.now()},
        changed: true,
      );
    });
  }

  try {
    return await commit(includeNotice: true);
  } on FirebaseException catch (error) {
    if (error.code != 'permission-denied') rethrow;
    // Las reglas solo aceptan omitir el aviso si la cuenta no lo recibe.
    return commit(includeNotice: false);
  }
}

Object? _status(Object? status) => switch (status) {
  'asignado' => 'assigned',
  'en proceso' => 'in_progress',
  'resuelto' => 'resolved',
  _ => status,
};
