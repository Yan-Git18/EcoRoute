import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/staff_task_entity.dart';
import '../repositories/staff_repository.dart';

/// Caso de uso para finalizar una tarea adjuntando foto de evidencia del área limpia.
///
/// Principio SRP: Responsabilidad única de validar y completar la atención del reporte.
///
/// Ubicación: `lib/features/staff/domain/usecases/complete_task_with_evidence_use_case.dart`
/// Capa: Domain (UseCases)
class CompleteTaskWithEvidenceUseCase {
  final StaffRepository _repository;

  const CompleteTaskWithEvidenceUseCase(this._repository);

  Future<Result<StaffTaskEntity>> call({
    required String taskId,
    required String staffId,
    required String staffName,
    required List<int> evidenceImageBytes,
    required String notes,
  }) async {
    if (taskId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'El identificador de la tarea es inválido.'),
      );
    }

    if (evidenceImageBytes.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Debe capturar o adjuntar una fotografía de evidencia de la limpieza.'),
      );
    }

    if (notes.trim().length < 3) {
      return const FailureResult(
        ValidationFailure(message: 'Ingrese una nota o comentario de resolución de al menos 3 caracteres.'),
      );
    }

    return await _repository.completeTaskWithEvidence(
      taskId: taskId,
      staffId: staffId,
      staffName: staffName,
      evidenceImageBytes: evidenceImageBytes,
      notes: notes.trim(),
    );
  }
}
