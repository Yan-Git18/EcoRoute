import '../../../../core/utils/result.dart';
import '../entities/report_category_entity.dart';
import '../entities/report_entity.dart';

/// Contrato del repositorio de reportes ciudadanos.
///
/// Ubicación: `lib/features/citizen/domain/repositories/report_repository.dart`
/// Capa: Domain (Repositories)
abstract class ReportRepository {
  /// Obtiene el catálogo de categorías de incidencias.
  Future<Result<List<ReportCategoryEntity>>> getCategories();

  /// Crea un nuevo reporte de residuos, opcionalmente subiendo la imagen de evidencia.
  Future<Result<ReportEntity>> createReport({
    required ReportEntity report,
    List<int>? imageBytes,
    String? imageFileName,
  });

  /// Obtiene los reportes creados por el ciudadano actual.
  Future<Result<List<ReportEntity>>> getMyReports(String citizenId);

  /// Obtiene el detalle de un reporte por su ID.
  Future<Result<ReportEntity>> getReportById(String reportId);

  /// Obtiene todos los reportes comunitarios públicos para el mapa y vista de cercanos.
  Future<Result<List<ReportEntity>>> getAllReports();
}
