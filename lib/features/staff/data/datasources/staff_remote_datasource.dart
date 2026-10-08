import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/errors/exceptions.dart';
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
    String? evidenceImageUrl,
  });
}

/// Implementación concreta de StaffRemoteDataSource con Cloud Firestore.
class FirebaseStaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  final FirebaseFirestore? _customFirestore;

  FirebaseStaffRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<List<StaffTaskDto>> getAssignedTasks(String staffId) async {
    if (!_isFirebaseReady && _customFirestore == null) return [];

    try {
      // Consultar reportes asignados al personal o globales pendientes/en proceso
      final snapshot = await _firestore
          .collection('reports')
          .where('status', whereIn: ['pending', 'assigned', 'in_progress', 'resolved'])
          .get();

      final list = snapshot.docs
          .map((doc) => StaffTaskDto.fromFirestore(doc.id, doc.data()))
          .toList();

      list.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
      return list;
    } catch (e) {
      throw ServerException(message: 'Error al consultar tareas de recolección: $e');
    }
  }

  @override
  Future<StaffTaskDto> getTaskById(String taskId) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada');
    }

    try {
      final doc = await _firestore.collection('reports').doc(taskId).get();
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
    String? evidenceImageUrl,
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
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null && notes.isNotEmpty) {
        updateData['resolutionNotes'] = notes;
      }

      if (evidenceImageUrl != null && evidenceImageUrl.isNotEmpty) {
        updateData['evidenceImageUrl'] = evidenceImageUrl;
      }

      await docRef.update(updateData);

      // Registrar auditoría en la subcolección 'history'
      try {
        await docRef.collection('history').add({
          'newStatus': newStatus.toDbString(),
          'changedByUserId': staffId,
          'changedByUserName': staffName,
          'changedByUserRole': 'staff',
          'comment': notes ?? 'Estado actualizado por el personal de limpieza.',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      final updatedDoc = await docRef.get();
      return StaffTaskDto.fromFirestore(taskId, updatedDoc.data() ?? {});
    } catch (e) {
      throw ServerException(message: 'Error al actualizar el estado de la tarea: $e');
    }
  }
}
