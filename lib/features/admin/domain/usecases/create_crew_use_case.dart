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
        ValidationFailure(
          message:
              'El nombre de la cuadrilla debe tener al menos 3 caracteres.',
        ),
      );
    }

    if (!crew.vehicleOnly && !crew.hasValidLeader) {
      return const FailureResult(
        ValidationFailure(message: 'Selecciona un líder del equipo.'),
      );
    }

    if (crew.vehiclePlate.trim().length < 3) {
      return const FailureResult(
        ValidationFailure(
          message: 'Ingrese una placa vehicular válida (ej. ECR-123).',
        ),
      );
    }

    final members = crew.memberIds;
    if (!crew.vehicleOnly &&
        (!MunicipalCrewEntity.isValidMemberCount(crew.crewMembersCount) ||
            (members != null &&
                (members.length != crew.crewMembersCount ||
                    members.toSet().length != members.length)))) {
      return const FailureResult(
        ValidationFailure(
          message: 'El equipo debe tener entre 2 y 5 integrantes.',
        ),
      );
    }

    return _repository.createCrew(
      crew.vehicleOnly
          ? crew.copyWith(leadStaffName: MunicipalCrewEntity.unassignedDriver)
          : crew,
    );
  }
}
