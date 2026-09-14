import '../../../../core/utils/result.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

/// Caso de uso para obtener la lista de reportes registrados por el ciudadano actual.
///
/// Ubicación: `lib/features/citizen/domain/usecases/get_my_reports_use_case.dart`
/// Capa: Domain (Use Cases)
class GetMyReportsUseCase {
  final ReportRepository _repository;

  const GetMyReportsUseCase(this._repository);

  Future<Result<List<ReportEntity>>> call(String citizenId) {
    return _repository.getMyReports(citizenId);
  }
}
