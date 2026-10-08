import '../../../../core/utils/result.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../entities/staff_task_entity.dart';

/// Contrato abstracto del repositorio para la gestión operativa de tareas de limpieza.
///
/// Principio ISP: Contrato enfocado exclusivamente en las operaciones del Personal de Limpieza.
///
/// Ubicación: `lib/features/staff/domain/repositories/staff_repository.dart`
/// Capa: Domain (Repositories)
abstract class StaffRepository {
  Future<Result<List<StaffTaskEntity>>> getAssignedTasks(String staffId);

  Future<Result<StaffTaskEntity>> getTaskById(String taskId);

  Future<Result<StaffTaskEntity>> updateTaskStatus({
    required String taskId,
    required String staffId,
    required String staffName,
    required ReportStatus newStatus,
    String? notes,
  });

  Future<Result<StaffTaskEntity>> completeTaskWithEvidence({
    required String taskId,
    required String staffId,
    required String staffName,
    required List<int> evidenceImageBytes,
    required String notes,
  });
}
