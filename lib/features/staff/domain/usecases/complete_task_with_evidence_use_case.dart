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
    List<int>? evidenceImageBytes,
    List<List<int>>? multipleEvidenceBytes,
    required String notes,
    String? localImagePath,
    List<String>? localImagePaths,
  }) async {
    if (taskId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'El identificador de la tarea es inválido.'),
      );
    }

    final hasSingle = evidenceImageBytes != null && evidenceImageBytes.isNotEmpty;
    final hasMultiple = multipleEvidenceBytes != null && multipleEvidenceBytes.isNotEmpty;

    if (!hasSingle && !hasMultiple) {
      return const FailureResult(
        ValidationFailure(message: 'Debe capturar o adjuntar al menos una fotografía de evidencia de la limpieza.'),
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
      multipleEvidenceBytes: multipleEvidenceBytes,
      notes: notes.trim(),
      localImagePath: localImagePath,
      localImagePaths: localImagePaths,
    );
  }
}
