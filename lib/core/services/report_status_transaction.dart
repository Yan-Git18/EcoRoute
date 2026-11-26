import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../errors/exceptions.dart';
import 'community_report_document.dart';
import 'firestore_media.dart';

class ReportAudit {
  const ReportAudit({
    required this.userId,
    required this.userName,
    required this.role,
    required this.comment,
  });

  final String userId;
  final String userName;
  final String role;
  final String comment;

  Map<String, dynamic> event(String previousStatus, String newStatus) => {
    'previousStatus': previousStatus,
    'newStatus': newStatus,
    'changedByUserId': userId,
    'changedByUserName': userName,
    'changedByUserRole': role,
    'comment': comment,
    'timestamp': FieldValue.serverTimestamp(),
  };
}

Future<Map<String, dynamic>> writeReportStatus({
  required DocumentReference<Map<String, dynamic>> report,
  required Map<String, dynamic> changes,
  ReportAudit? audit,
  Future<Map<String, dynamic>> Function(
    Transaction transaction,
    Map<String, dynamic> current,
  )?
  prepare,
  Future<void Function(Transaction)?> Function(
    Transaction transaction,
    Map<String, dynamic> current,
  )?
  stageRelatedWrites,

  List<Uint8List> evidencePhotos = const [],
}) async {
  final firestore = report.firestore;
  final eventId = const Uuid().v4();
  final nextStatus = changes['status'] as String?;
  final sendsNotice = const {
    'assigned',
    'in_progress',
    'resolved',
  }.contains(nextStatus);
  assert((nextStatus == null) == (audit == null));

  Future<Map<String, dynamic>> commit({required bool includeNotice}) {
    return firestore.runTransaction((transaction) async {
      final current = (await transaction.get(report)).data();
      if (current == null) {
        throw const ServerException(message: 'El reporte no existe.');
      }
      final previousStatus = _status(current['status']);
      final prepared = await prepare?.call(transaction, current);
      final updates = {
        ...changes,
        ...?prepared,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (nextStatus == previousStatus &&
          (nextStatus == 'cancelled' ||
              (nextStatus == 'resolved' &&
                  current['assignedStaffId'] == audit?.userId))) {
        return current;
      }

      final writeRelated = await stageRelatedWrites?.call(transaction, current);
      final previousCrew = _openCrew(current);
      final nextCrew = _openCrew({...current, ...updates});
      final crews = firestore.collection('crews');
      final releasedCrew =
          audit != null && previousCrew != null && previousCrew != nextCrew
          ? (await transaction.get(crews.doc(previousCrew))).data()
          : null;

      final releasesRouteTask = nextStatus == 'pending' &&
          previousStatus == 'in_progress' &&
          current['collectionRouteId'] != null &&
          changes['collectionRouteId'] is FieldValue;

      if (audit != null &&
          (releasesRouteTask || nextStatus == 'in_progress' || nextStatus == 'resolved')) {
        final resolvingCrewReport =
            (nextStatus == 'resolved' || releasesRouteTask) && previousCrew != null;
        final assignee = current['assignedStaffId'];
        final activeOwner =
            resolvingCrewReport && assignee is String && assignee.isNotEmpty
            ? assignee
            : audit.userId;
        final active = firestore.doc(
          'users/$activeOwner/operations/activeTask',
        );
        if (!resolvingCrewReport) {
          final activeIds =
              ((await transaction.get(active)).data()?['reportIds'] as List?)
                  ?.cast<String>() ??
              const <String>[];
          if (nextStatus == 'in_progress' && activeIds.isNotEmpty) {
            if (previousStatus == 'in_progress' &&
                activeIds.contains(report.id) &&
                current['assignedStaffId'] == audit.userId) {
              return current;
            }
            throw const ServerException(
              message:
                  'Ya tienes una tarea en curso. Ciérrala antes de iniciar otra.',
              code: 'active-task-exists',
            );
          }
          if (nextStatus == 'resolved' && !activeIds.contains(report.id)) {
            throw const ServerException(
              message: 'La tarea no figura entre tus tareas en curso.',
            );
          }
        }
        transaction.set(
          active,
          {
            'reportIds': nextStatus == 'in_progress'
                ? [report.id]
                : FieldValue.arrayRemove([report.id]),
            'reportId': report.id,
            'eventId': eventId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      if (evidencePhotos.isNotEmpty) {
        final media = report.collection('media');
        final evidence = List.generate(
          evidencePhotos.length,
          (index) => media.doc(index == 0 ? 'evidence' : 'evidence_$index'),
        );
        updates['evidenceImagePath'] = evidence.first.path;
        if (evidence.length > 1) {
          updates['evidenceImagePaths'] = evidence
              .map((photo) => photo.path)
              .toList();
        }
        for (var index = 0; index < evidence.length; index++) {
          transaction.set(
            evidence[index],
            FirestoreMedia.document(evidencePhotos[index]),
          );
        }
      }

      if (audit != null && nextStatus != null) {
        updates['statusEventId'] = eventId;
        transaction.set(
          report.collection('history').doc(eventId),
          audit.event(previousStatus, nextStatus),
        );
        if (previousCrew != nextCrew) {
          for (final (crewId, delta) in [(previousCrew, -1), (nextCrew, 1)]) {
            if (crewId == null) continue;
            final returnsToAvailable =
                delta < 0 &&
                releasedCrew?['openReportCount'] == 1 &&
                const ['onRoute', 'on_route'].contains(releasedCrew?['status']);
            transaction.update(crews.doc(crewId), {
              'openReportCount': FieldValue.increment(delta),
              'reportActivity': {'reportId': report.id, 'eventId': eventId},
              if (delta > 0) 'status': 'onRoute',
              if (returnsToAvailable) 'status': 'available',
              if (delta > 0 || returnsToAvailable)
                'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        final owner = current['citizenId'];
        if (includeNotice &&
            previousStatus != nextStatus &&
            owner is String &&
            owner.isNotEmpty) {
          final notice = firestore
              .collection('users')
              .doc(owner)
              .collection('notifications')
              .doc(eventId);
          transaction.set(notice, {
            'reportId': report.id,
            'reportNumber': current['reportNumber'] ?? report.id,
            'status': nextStatus,
            'createdAt': FieldValue.serverTimestamp(),
            'readAt': null,
            'pushPending': true,
          });
        }
      }

      final after = {...current, ...updates};
      writeRelated?.call(transaction);
      transaction.update(report, updates);
      transaction.set(
        communityReportRef(report),
        communityReportDocument(after),
      );
      return {...after, 'updatedAt': Timestamp.now()};
    });
  }

  try {
    return await commit(includeNotice: sendsNotice);
  } on FirebaseException catch (error) {
    if (!sendsNotice || error.code != 'permission-denied') rethrow;
    // El cliente no tiene acceso a las preferencias de otro usuario.
    return commit(includeNotice: false);
  }
}

String? _openCrew(Map<String, dynamic> report) {
  final status = _status(report['status']);
  final crewId = report['assignedToTeamId'];
  return (status == 'assigned' || status == 'in_progress') &&
          crewId is String &&
          crewId.isNotEmpty
      ? crewId
      : null;
}

String _status(Object? value) => switch (value) {
  'pendiente' => 'pending',
  'asignado' => 'assigned',
  'en proceso' => 'in_progress',
  'resuelto' => 'resolved',
  'cancelado' => 'cancelled',
  String status => status,
  _ => 'pending',
};
