import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/staff_operations.dart';
import '../../domain/repositories/staff_operations_repository.dart';
import '../models/staff_task_dto.dart';

class FirebaseStaffOperationsRepository implements StaffOperationsRepository {
  const FirebaseStaffOperationsRepository(this._db);

  final FirebaseFirestore? _db;

  @override
  Stream<String?> watchTeamId(String uid) {
    final profile = _db?.collection('users').doc(uid);
    if (profile == null) return Stream.value(null);
    return profile
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map((snapshot) => _field(snapshot.data(), 'teamId'))
        .distinct();
  }

  @override
  Stream<StaffCrew?> watchCrew(String teamId) {
    final crew = _db?.collection('crews').doc(teamId);
    if (crew == null) return Stream.value(null);
    return crew
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) return null;
          final members = data['memberIds'] as List?;
          return StaffCrew(
            id: teamId,
            name: _field(data, 'name'),
            zone: _field(data, 'zone'),
            vehicleCode: _field(data, 'vehicleCode'),
            vehiclePlate: _field(data, 'vehiclePlate'),
            leaderId: _field(data, 'leaderId') ??
                (members?.firstOrNull as String?),
            leaderName: _field(data, 'leadStaffName'),
          );
        });
  }

  @override
  Stream<int> watchTeamTaskChanges(String teamId) {
    final reports = _db?.collection('reports');
    if (reports == null) return const Stream.empty();
    var revision = 0;
    return reports
        .where('assignedToTeamId', isEqualTo: teamId)
        .where('status', whereIn: StaffTaskDto.openStatuses)
        .snapshots(includeMetadataChanges: true)
        .where(
          (snapshot) =>
              !snapshot.metadata.isFromCache &&
              !snapshot.metadata.hasPendingWrites,
        )
        .map((_) => ++revision);
  }

  @override
  Stream<StaffShift?> watchShift(String uid) {
    final shift = _shift(uid);
    if (shift == null) return Stream.value(null);
    return shift
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) return null;
          return StaffShift(
            status: StaffShiftStatus.fromValue(data['status']),
            sessionId: data['sessionId'] as String,
          );
        });
  }

  @override
  Stream<List<StaffShiftEvent>> watchShiftEvents(String uid, String sessionId) {
    final events = _events(uid);
    if (events == null) return Stream.value(const []);
    return events
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              if (doc.data()['changedAt'] case final Timestamp timestamp)
                StaffShiftEvent(
                  status: StaffShiftStatus.fromValue(doc.data()['status']),
                  changedAt: timestamp.toDate(),
                ),
          ],
        );
  }

  @override
  Future<void> changeShift(String uid, StaffShiftStatus status) async {
    final db = _db;
    final shift = _shift(uid);
    final event = _events(uid)?.doc();
    if (db == null || shift == null || event == null) {
      throw StateError('Base de datos no inicializada.');
    }
    await db.runTransaction((transaction) async {
      final current = (await transaction.get(shift)).data();
      final previous = current == null
          ? StaffShiftStatus.offDuty
          : StaffShiftStatus.fromValue(current['status']);
      if (previous == status) return;
      if (!previous.canChangeTo(status)) {
        throw StateError(
          'El turno debe estar iniciado para registrar un descanso.',
        );
      }

      final fields = {
        'status': status.value,
        'sessionId': previous == StaffShiftStatus.offDuty
            ? event.id
            : current!['sessionId'],
        'changedAt': FieldValue.serverTimestamp(),
      };
      transaction.set(shift, {...fields, 'eventId': event.id});
      transaction.set(event, fields);
    });
  }

  DocumentReference<Map<String, dynamic>>? _shift(String uid) =>
      _db?.doc('users/$uid/operations/shift');

  CollectionReference<Map<String, dynamic>>? _events(String uid) =>
      _db?.collection('users/$uid/shiftEvents');

  static String? _field(Map<String, dynamic>? data, String key) {
    final value = data?[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }
}
