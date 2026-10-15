import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

/// Caso de uso para que un ciudadano cancele un reporte que se encuentre en estado pendiente.
///
/// Ubicación: `lib/features/citizen/domain/usecases/cancel_report_use_case.dart`
/// Capa: Domain (Use Cases)
class CancelReportUseCase {
  final ReportRepository _repository;

  const CancelReportUseCase(this._repository);

  Future<Result<ReportEntity>> call({
    required String reportId,
    String? reason,
  }) async {
    if (reportId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'El identificador del reporte es requerido.'),
      );
    }

    return _repository.cancelReport(
      reportId: reportId.trim(),
      reason: reason?.trim(),
    );
  }
}
