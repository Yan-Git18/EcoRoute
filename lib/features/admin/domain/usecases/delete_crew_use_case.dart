import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso para dar de baja o eliminar una cuadrilla del registro municipal.
///
/// Principio SRP: Gestiona la eliminación de una cuadrilla con validación de ID.
/// Ubicación: `lib/features/admin/domain/usecases/delete_crew_use_case.dart`
/// Capa: Domain (Use Cases)
class DeleteCrewUseCase {
  final AdminRepository _repository;

  const DeleteCrewUseCase(this._repository);

  Future<Result<void>> call(String crewId) async {
    if (crewId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Identificador de cuadrilla no válido.'),
      );
    }

    return _repository.deleteCrew(crewId);
  }
}

