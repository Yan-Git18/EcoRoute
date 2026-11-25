import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/report_status_transaction.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../models/staff_task_dto.dart';

/// Contrato abstracto para la fuente de datos remota de tareas del Personal de Limpieza.
///
/// Principio ISP / SRP: Métodos enfocado exclusivamente en la consulta y cambio de estado de tareas.
abstract class StaffRemoteDataSource {
  Future<List<StaffTaskDto>> getAssignedTasks(String staffId);

  Future<StaffTaskDto> getTaskById(String taskId);

  Future<StaffTaskDto> updateTaskStatus({
    required String taskId,
    required String staffId,
    required String staffName,
    required ReportStatus newStatus,
    String? notes,
    List<Uint8List> evidencePhotos = const [],
  });
}

/// Implementación concreta de StaffRemoteDataSource con Cloud Firestore.
class FirebaseStaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  static const _server = GetOptions(source: Source.server);

  final FirebaseFirestore? _customFirestore;

  FirebaseStaffRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<List<StaffTaskDto>> getAssignedTasks(String staffId) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada.');
    }

    try {
      final profile = await _firestore.collection('users').doc(staffId).get(_server);
      final user = profile.data();
      if (user == null ||
          UserRole.fromString(user['role'] as String? ?? '') != UserRole.staff ||
          user['isActive'] == false) {
        throw const ServerException(message: 'La sesión no tiene acceso a tareas de personal.');
      }

      final teamId = user['teamId'];
      final personal = Filter.and(
        Filter('assignedStaffId', isEqualTo: staffId),
        Filter('status', whereIn: StaffTaskDto.visibleStatuses),
      );
      final individualRoster = Filter.and(
        Filter('assignedStaffIds', arrayContains: staffId),
        Filter('status', whereIn: StaffTaskDto.assignedStatuses),
      );
      final visible = teamId is String && teamId.isNotEmpty
          ? Filter.or(
              personal,
              individualRoster,
              Filter.and(
                Filter('assignedToTeamId', isEqualTo: teamId),
                Filter('status', whereIn: StaffTaskDto.visibleStatuses),
              ),
            )
          : Filter.or(personal, individualRoster);
      final snapshot = await _firestore
          .collection('reports')
          .where(visible)
          .get(_server);

      return snapshot.docs.where((doc) {
        final data = doc.data();
        final assignee = data['assignedStaffId'];
        return (teamId is String && teamId.isNotEmpty &&
                data['assignedToTeamId'] == teamId) ||
            assignee == null ||
            assignee == staffId;
      }).map((doc) => StaffTaskDto.fromFirestore(doc.id, doc.data())).toList();
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'No se pudieron cargar las tareas asignadas.',
        code: e.code,
      );
    }
  }

  @override
  Future<StaffTaskDto> getTaskById(String taskId) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada');
    }

    try {
      final doc = await _firestore.collection('reports').doc(taskId).get(_server);
      if (!doc.exists || doc.data() == null) {
        throw const ServerException(message: 'La tarea solicitada no existe.');
      }

      return StaffTaskDto.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      throw ServerException(message: 'Error al consultar la tarea: $e');
    }
  }

  @override
  Future<StaffTaskDto> updateTaskStatus({
    required String taskId,
    required String staffId,
    required String staffName,
    required ReportStatus newStatus,
    String? notes,
    List<Uint8List> evidencePhotos = const [],
  }) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada.');
    }

    try {
      final docRef = _firestore.collection('reports').doc(taskId);

      final updateData = <String, dynamic>{
        'status': newStatus.toDbString(),
        'assignedStaffId': staffId,
        'assignedStaffName': staffName,
        if (newStatus == ReportStatus.resolved)
          'resolvedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == ReportStatus.resolved && notes != null && notes.isNotEmpty) {
        updateData['resolutionNotes'] = notes;
      }

      final fields = await writeReportStatus(
        report: docRef,
        changes: updateData,
        audit: ReportAudit(
          userId: staffId,
          userName: staffName,
          role: 'staff',
          comment: notes ?? 'Estado actualizado por el personal de limpieza.',
        ),
        evidencePhotos: evidencePhotos,
      );
      return StaffTaskDto.fromFirestore(taskId, {
        ...fields,
        if (fields['resolvedAt'] is FieldValue) 'resolvedAt': fields['updatedAt'],
      });
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.code == 'permission-denied'
            ? 'La tarea ya no está disponible para esta sesión.'
            : 'No se pudo actualizar el estado de la tarea.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Error al actualizar el estado de la tarea: $e');
    }
  }
}
