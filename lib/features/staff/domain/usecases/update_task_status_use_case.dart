import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../entities/staff_task_entity.dart';
import '../repositories/staff_repository.dart';

/// Caso de uso para cambiar el estado de una tarea (p. ej. de "Asignado" a "En proceso").
///
/// Principio SRP: Responsabilidad única de actualizar el estado de una tarea.
///
/// Ubicación: `lib/features/staff/domain/usecases/update_task_status_use_case.dart`
/// Capa: Domain (UseCases)
class UpdateTaskStatusUseCase {
  final StaffRepository _repository;

  const UpdateTaskStatusUseCase(this._repository);

  Future<Result<StaffTaskEntity>> call({
    required String taskId,
    required String staffId,
    required String staffName,
    required ReportStatus newStatus,
    String? notes,
  }) async {
    if (taskId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'El identificador de la tarea es inválido.'),
      );
    }

    return await _repository.updateTaskStatus(
      taskId: taskId,
      staffId: staffId,
      staffName: staffName,
      newStatus: newStatus,
      notes: notes,
    );
  }
}
