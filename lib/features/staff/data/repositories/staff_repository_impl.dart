import 'dart:typed_data';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/image_compression.dart';
import '../../../../core/utils/result.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/staff_task_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_remote_datasource.dart';

/// Implementación del repositorio de tareas de limpieza.
///
/// Traduce las respuestas de la fuente de datos al dominio de Staff.
///
/// Ubicación: `lib/features/staff/data/repositories/staff_repository_impl.dart`
/// Capa: Data (Repositories)
class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDataSource _remoteDataSource;

  StaffRepositoryImpl({
    StaffRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? FirebaseStaffRemoteDataSourceImpl();

  @override
  Future<Result<List<StaffTaskEntity>>> getAssignedTasks(String staffId) async {
    try {
      final dtos = await _remoteDataSource.getAssignedTasks(staffId);
      final tasks = dtos.map((dto) => dto.toDomain()).toList()
        ..sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
      return Success(tasks);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (_) {
      return const FailureResult(
        ServerFailure(message: 'No se pudieron cargar las tareas asignadas.'),
      );
    }
  }

  @override
  Future<Result<StaffTaskEntity>> getTaskById(String taskId) async {
    try {
      final dto = await _remoteDataSource.getTaskById(taskId);
      return Success(dto.toDomain());
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
      return Success(dto.toDomain());
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (_) {
      return const FailureResult(ServerFailure(message: 'No se pudo actualizar el estado de la tarea.'));
    }
  }

  @override
  Future<Result<StaffTaskEntity>> completeTaskWithEvidence({
    required String taskId,
    required String staffId,
    required String staffName,
    List<int>? evidenceImageBytes,
    List<List<int>>? multipleEvidenceBytes,
    required String notes,
  }) async {
    final originals = multipleEvidenceBytes?.isNotEmpty == true
        ? multipleEvidenceBytes!
        : [if (evidenceImageBytes != null) evidenceImageBytes];
    if (originals.isEmpty || originals.length > StaffTaskEntity.maxEvidencePhotos) {
      return const FailureResult(
        ValidationFailure(message: 'Adjunta entre 1 y ${StaffTaskEntity.maxEvidencePhotos} fotografías de evidencia.'),
      );
    }
    try {
      final photos = <Uint8List>[];
      for (final bytes in originals) {
        photos.add(await compressPhoto(bytes, PhotoSize.report));
      }
      final dto = await _remoteDataSource.updateTaskStatus(
        taskId: taskId,
        staffId: staffId,
        staffName: staffName,
        newStatus: ReportStatus.resolved,
        notes: notes,
        evidencePhotos: photos,
      );
      return Success(dto.toDomain());
    } on PhotoCompressionException catch (error) {
      return FailureResult(ValidationFailure(message: error.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (_) {
      return const FailureResult(ServerFailure(message: 'Error al finalizar la tarea con evidencia.'));
    }
  }
}
