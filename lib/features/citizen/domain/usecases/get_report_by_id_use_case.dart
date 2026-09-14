import '../../../../core/utils/result.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

/// Caso de uso para obtener el detalle de un reporte específico por su ID.
///
/// Ubicación: `lib/features/citizen/domain/usecases/get_report_by_id_use_case.dart`
/// Capa: Domain (Use Cases)
class GetReportByIdUseCase {
  final ReportRepository _repository;

  const GetReportByIdUseCase(this._repository);

  Future<Result<ReportEntity>> call(String reportId) {
    return _repository.getReportById(reportId);
  }
}
