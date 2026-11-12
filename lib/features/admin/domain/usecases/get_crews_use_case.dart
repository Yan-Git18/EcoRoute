import '../../../../core/utils/result.dart';
import '../entities/municipal_crew_entity.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso para consultar las cuadrillas municipales activas y su estado operativo.
///
/// Principio SRP: Responsable único de obtener la flota municipal del repositorio.
/// Ubicación: `lib/features/admin/domain/usecases/get_crews_use_case.dart`
/// Capa: Domain (Use Cases)
class GetCrewsUseCase {
  final AdminRepository _repository;

  const GetCrewsUseCase(this._repository);

  Future<Result<List<MunicipalCrewEntity>>> call() {
    return _repository.getAvailableCrews();
  }
}

