import '../../../../core/utils/result.dart';
import '../entities/report_category_entity.dart';
import '../entities/report_entity.dart';

/// Contrato del repositorio de reportes ciudadanos.
/// Capa: Domain (Repositories)
abstract class ReportRepository {
  /// Obtiene el catálogo de categorías de incidencias.
  Future<Result<List<ReportCategoryEntity>>> getCategories();

  /// Crea un nuevo reporte de residuos, opcionalmente subiendo imágenes de evidencia.
  Future<Result<ReportEntity>> createReport({
    required ReportEntity report,
    List<int>? imageBytes,
    String? imageFileName,
    List<List<int>>? multipleImageBytes,
    List<String>? localImagePaths,
  });

  /// Obtiene los reportes creados por el ciudadano actual.
  Future<Result<List<ReportEntity>>> getMyReports(String citizenId);

  /// Obtiene el detalle de un reporte por su ID.
  Future<Result<ReportEntity>> getReportById(String reportId);

  /// Obtiene todos los reportes comunitarios públicos para el mapa y vista de cercanos.
  Future<Result<List<ReportEntity>>> getAllReports();

  /// Cancela un reporte ciudadano que se encuentra en estado pendiente.
  Future<Result<ReportEntity>> cancelReport({required String reportId, String? reason});
}
