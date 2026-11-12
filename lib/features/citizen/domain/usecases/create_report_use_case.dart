import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

/// Caso de uso para validar y registrar un reporte ciudadano en el sistema.
///
/// Ubicación: `lib/features/citizen/domain/usecases/create_report_use_case.dart`
/// Capa: Domain (Use Cases)
class CreateReportUseCase {
  final ReportRepository _repository;

  const CreateReportUseCase(this._repository);

  Future<Result<ReportEntity>> call({
    required ReportEntity report,
    List<int>? imageBytes,
    String? imageFileName,
    List<List<int>>? multipleImageBytes,
    List<String>? localImagePaths,
  }) async {
    // Validaciones de reglas de negocio
    if (report.categoryId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Debe seleccionar una categoría para el reporte.'),
      );
    }

    if (report.description.trim().length < 5) {
      return const FailureResult(
        ValidationFailure(
          message: 'La descripción debe contener al menos 5 caracteres detallando el problema.',
        ),
      );
    }

    if (report.address.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Debe especificar una dirección o ubicación válida.'),
      );
    }

    final hasImages = (imageBytes != null && imageBytes.isNotEmpty) ||
        (multipleImageBytes != null && multipleImageBytes.isNotEmpty) ||
        (localImagePaths != null && localImagePaths.isNotEmpty) ||
        report.imageUrls.isNotEmpty ||
        report.evidenceImageUrls.isNotEmpty;
    if (!hasImages) {
      return const FailureResult(
        ValidationFailure(
          message: 'Debe adjuntar al menos una fotografía de evidencia tomada al instante.',
        ),
      );
    }

    return _repository.createReport(
      report: report,
      imageBytes: imageBytes,
      imageFileName: imageFileName,
      multipleImageBytes: multipleImageBytes,
      localImagePaths: localImagePaths,
    );
  }
}
