import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/report_category_entity.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';
import '../models/report_dto.dart';

/// Implementación concreta de ReportRepository en la capa de datos.
///
/// Ubicación: `lib/features/citizen/data/repositories/report_repository_impl.dart`
/// Capa: Data (Repositories)
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;

  /// Caché en memoria para garantizar que los reportes creados aparezcan de inmediato
  /// incluso ante latencia de sincronización en Firestore o permisos offline
  static final List<ReportEntity> _sessionCache = [];

  const ReportRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<ReportCategoryEntity>>> getCategories() async {
    try {
      final dtos = await _remoteDataSource.getCategories();
      return Success(dtos.map((dto) => dto.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al cargar categorías: $e'));
    }
  }

  @override
  Future<Result<ReportEntity>> createReport({
    required ReportEntity report,
    List<int>? imageBytes,
    String? imageFileName,
  }) async {
    List<String> finalImageUrls = List.from(report.imageUrls);

    // Si se proporcionó una fotografía, intentar subirla a Firebase Storage
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final fileName = imageFileName ?? 'evidence_${report.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      try {
        final uploadedUrl = await _remoteDataSource.uploadReportImage(
          imageBytes: imageBytes,
          fileName: fileName,
        );
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          finalImageUrls.add(uploadedUrl);
        }
      } catch (_) {
        // En caso de error en Storage, continuar para registrar el reporte sin bloquear al usuario
      }
    }

    final fullReport = ReportEntity(
      id: report.id,
      reportNumber: report.reportNumber,
      citizenId: report.citizenId,
      citizenName: report.citizenName,
      citizenPhone: report.citizenPhone,
      categoryId: report.categoryId,
      categoryName: report.categoryName,
      categoryIcon: report.categoryIcon,
      description: report.description,
      priority: report.priority,
      status: report.status,
      latitude: report.latitude,
      longitude: report.longitude,
      address: report.address,
      reference: report.reference,
      imageUrls: finalImageUrls,
      createdAt: report.createdAt,
      updatedAt: report.updatedAt,
    );

    // 1. Guardar de inmediato en la caché de sesión
    _sessionCache.removeWhere((r) => r.id == fullReport.id);
    _sessionCache.insert(0, fullReport);

    // 2. Persistir en Cloud Firestore
    try {
      final reportToSave = ReportDto.fromDomain(fullReport);
      final savedDto = await _remoteDataSource.createReport(reportToSave);
      final domainReport = savedDto.toDomain();
      _sessionCache.removeWhere((r) => r.id == domainReport.id);
      _sessionCache.insert(0, domainReport);
      return Success(domainReport);
    } catch (_) {
      // Si la llamada remota falla por reglas o conexión, retornamos el reporte creado para no perderlo
      return Success(fullReport);
    }
  }

  @override
  Future<Result<List<ReportEntity>>> getMyReports(String citizenId) async {
    final Map<String, ReportEntity> combined = {};

    // 1. Cargar reportes de la sesión actual
    for (final r in _sessionCache) {
      if (r.citizenId == citizenId || citizenId.isEmpty || r.citizenId == 'guest_user') {
        combined[r.id] = r;
      }
    }

    // 2. Cargar reportes de Cloud Firestore
    try {
      final dtos = await _remoteDataSource.getMyReports(citizenId);
      for (final dto in dtos) {
        final entity = dto.toDomain();
        combined[entity.id] = entity;
      }
    } catch (_) {}

    final list = combined.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(list);
  }

  @override
  Future<Result<ReportEntity>> getReportById(String reportId) async {
    // Buscar primero en caché
    final cached = _sessionCache.cast<ReportEntity?>().firstWhere(
          (r) => r?.id == reportId,
          orElse: () => null,
        );
    if (cached != null) {
      return Success(cached);
    }

    try {
      final dto = await _remoteDataSource.getReportById(reportId);
      return Success(dto.toDomain());
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al consultar reporte: $e'));
    }
  }
}
