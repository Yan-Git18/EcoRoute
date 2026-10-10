import '../../../../core/utils/result.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../entities/municipal_crew_entity.dart';

/// Contrato del repositorio para la administración municipal de reportes y cuadrillas.
///
/// Principio ISP / SRP: Métodos orientados a la supervisión y despacho administrativo.
///
/// Ubicación: `lib/features/admin/domain/repositories/admin_repository.dart`
/// Capa: Domain (Admin)
abstract class AdminRepository {
  /// Obtiene todos los reportes comunitarios para la bandeja administrativa.
  Future<Result<List<ReportEntity>>> getAllReports();

  /// Obtiene la lista de cuadrillas municipales registradas y su disponibilidad.
  Future<Result<List<MunicipalCrewEntity>>> getAvailableCrews();

  /// Asigna un reporte ciudadano a una cuadrilla y unidad vehicular determinada.
  Future<Result<ReportEntity>> assignReportToCrew({
    required String reportId,
    required MunicipalCrewEntity crew,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  });

  /// Permite cambiar o escalar la prioridad de un reporte desde la central.
  Future<Result<ReportEntity>> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  });
}
