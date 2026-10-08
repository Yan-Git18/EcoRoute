import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/staff_task_entity.dart';
import '../repositories/staff_repository.dart';

/// Caso de uso para obtener la lista de tareas de limpieza asignadas al personal.
///
/// Principio SRP: Responsabilidad única de consultar tareas asignadas.
///
/// Ubicación: `lib/features/staff/domain/usecases/get_assigned_tasks_use_case.dart`
/// Capa: Domain (UseCases)
class GetAssignedTasksUseCase {
  final StaffRepository _repository;

  const GetAssignedTasksUseCase(this._repository);

  Future<Result<List<StaffTaskEntity>>> call(String staffId) async {
    if (staffId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'El identificador del personal es requerido.'),
      );
    }
    return await _repository.getAssignedTasks(staffId);
  }
}
