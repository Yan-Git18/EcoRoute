import '../../../../core/utils/result.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

/// Caso de uso para obtener todos los reportes comunitarios para el mapa urbano y reportes cercanos.
///
/// Principio SRP: Responsabilidad única de orquestar la obtención de reportes públicos para la comunidad.
///
/// Ubicación: `lib/features/citizen/domain/usecases/get_all_reports_use_case.dart`
/// Capa: Domain (Use Cases)
class GetAllReportsUseCase {
  final ReportRepository _repository;

  const GetAllReportsUseCase(this._repository);

  Future<Result<List<ReportEntity>>> call() {
    return _repository.getAllReports();
  }
}
