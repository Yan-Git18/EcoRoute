import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/municipal_crew_entity.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso para modificar los datos operativos de una cuadrilla municipal.
///
/// Principio SRP: Aplica reglas de validación en la actualización operativa de la unidad.
/// Ubicación: `lib/features/admin/domain/usecases/update_crew_use_case.dart`
/// Capa: Domain (Use Cases)
class UpdateCrewUseCase {
  final AdminRepository _repository;

  const UpdateCrewUseCase(this._repository);

  Future<Result<MunicipalCrewEntity>> call(MunicipalCrewEntity crew) async {
    if (crew.id.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Identificador de cuadrilla no válido.'),
      );
    }

    if (crew.name.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'El nombre de la cuadrilla no puede estar vacío.'),
      );
    }

    final members = crew.memberIds;
    if (!crew.vehicleOnly &&
        members != null &&
        (members.isNotEmpty || crew.leaderId != null) &&
        !crew.hasValidLeader) {
      return const FailureResult(
        ValidationFailure(message: 'Selecciona un líder del equipo.'),
      );
    }

    return _repository.updateCrew(crew);
  }
}

