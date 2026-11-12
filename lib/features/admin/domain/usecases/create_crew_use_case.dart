import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/municipal_crew_entity.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso para registrar y dar de alta una nueva cuadrilla municipal.
///
/// Principio SRP: Aplica reglas de negocio y validaciones antes de persistir.
/// Ubicación: `lib/features/admin/domain/usecases/create_crew_use_case.dart`
/// Capa: Domain (Use Cases)
class CreateCrewUseCase {
  final AdminRepository _repository;

  const CreateCrewUseCase(this._repository);

  Future<Result<MunicipalCrewEntity>> call(MunicipalCrewEntity crew) async {
    // 1. Validación de reglas de negocio
    if (crew.name.trim().length < 3) {
      return const FailureResult(
        ValidationFailure(message: 'El nombre de la cuadrilla debe tener al menos 3 caracteres.'),
      );
    }

    if (crew.zone.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Debe asignar una zona o sector de cobertura.'),
      );
    }

    if (crew.leadStaffName.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Debe especificar el nombre del responsable o líder.'),
      );
    }

    if (crew.vehiclePlate.trim().length < 3) {
      return const FailureResult(
        ValidationFailure(message: 'Ingrese una placa vehicular válida (ej. ECR-123).'),
      );
    }

    if (crew.crewMembersCount < 1) {
      return const FailureResult(
        ValidationFailure(message: 'La cuadrilla debe contar con al menos 1 integrante.'),
      );
    }

    return _repository.createCrew(crew);
  }
}

