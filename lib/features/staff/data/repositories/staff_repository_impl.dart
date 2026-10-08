import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/staff_task_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_remote_datasource.dart';
import '../datasources/staff_storage_datasource.dart';

/// Implementación del repositorio de tareas de limpieza.
///
/// Principio SRP / DIP: Compone los data sources de Staff y maneja la caché en memoria.
///
/// Ubicación: `lib/features/staff/data/repositories/staff_repository_impl.dart`
/// Capa: Data (Repositories)
class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDataSource _remoteDataSource;
  final StaffStorageDataSource _storageDataSource;

  static final Map<String, StaffTaskEntity> _taskCache = {};

  StaffRepositoryImpl({
    StaffRemoteDataSource? remoteDataSource,
    StaffStorageDataSource? storageDataSource,
  })  : _remoteDataSource = remoteDataSource ?? FirebaseStaffRemoteDataSourceImpl(),
        _storageDataSource = storageDataSource ?? FirebaseStaffStorageDataSourceImpl();

  @override
  Future<Result<List<StaffTaskEntity>>> getAssignedTasks(String staffId) async {
    final Map<String, StaffTaskEntity> combined = Map.from(_taskCache);

    try {
      final dtos = await _remoteDataSource.getAssignedTasks(staffId);
      for (final dto in dtos) {
        final entity = dto.toDomain();
        combined[entity.id] = entity;
        _taskCache[entity.id] = entity;
      }
    } catch (_) {}

    final list = combined.values.toList();
    list.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
    return Success(list);
  }

  @override
  Future<Result<StaffTaskEntity>> getTaskById(String taskId) async {
    if (_taskCache.containsKey(taskId)) {
      return Success(_taskCache[taskId]!);
    }

    try {
      final dto = await _remoteDataSource.getTaskById(taskId);
      final entity = dto.toDomain();
      _taskCache[entity.id] = entity;
      return Success(entity);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al consultar la tarea: $e'));
    }
  }

  @override
  Future<Result<StaffTaskEntity>> updateTaskStatus({
    required String taskId,
    required String staffId,
    required String staffName,
    required ReportStatus newStatus,
    String? notes,
  }) async {
    try {
      final dto = await _remoteDataSource.updateTaskStatus(
        taskId: taskId,
        staffId: staffId,
        staffName: staffName,
        newStatus: newStatus,
        notes: notes,
      );
      final entity = dto.toDomain();
      _taskCache[entity.id] = entity;
      return Success(entity);
    } catch (_) {
      // Fallback amigable para actualizar caché local
      final existing = _taskCache[taskId];
      if (existing != null) {
        final updated = existing.copyWith(
          status: newStatus,
          resolutionNotes: notes ?? existing.resolutionNotes,
          updatedAt: DateTime.now(),
        );
        _taskCache[taskId] = updated;
        return Success(updated);
      }
      return const FailureResult(ServerFailure(message: 'No se pudo actualizar el estado de la tarea.'));
    }
  }

  @override
  Future<Result<StaffTaskEntity>> completeTaskWithEvidence({
    required String taskId,
    required String staffId,
    required String staffName,
    required List<int> evidenceImageBytes,
    required String notes,
  }) async {
    String? evidenceUrl;

    if (evidenceImageBytes.isNotEmpty) {
      final fileName = 'evidence_${taskId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      try {
        evidenceUrl = await _storageDataSource.uploadEvidenceImage(
          imageBytes: evidenceImageBytes,
          fileName: fileName,
        );
      } catch (_) {}
    }

    try {
      final dto = await _remoteDataSource.updateTaskStatus(
        taskId: taskId,
        staffId: staffId,
        staffName: staffName,
        newStatus: ReportStatus.resolved,
        notes: notes,
        evidenceImageUrl: evidenceUrl,
      );
      final entity = dto.toDomain();
      _taskCache[entity.id] = entity;
      return Success(entity);
    } catch (_) {
      final existing = _taskCache[taskId];
      if (existing != null) {
        final updated = existing.copyWith(
          status: ReportStatus.resolved,
          evidenceImageUrl: evidenceUrl,
          resolutionNotes: notes,
          updatedAt: DateTime.now(),
        );
        _taskCache[taskId] = updated;
        return Success(updated);
      }
      return const FailureResult(ServerFailure(message: 'Error al finalizar la tarea con evidencia.'));
    }
  }
}
