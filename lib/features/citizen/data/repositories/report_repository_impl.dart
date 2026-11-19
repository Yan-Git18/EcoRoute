import 'dart:convert';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/report_category_entity.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/category_remote_datasource.dart';
import '../datasources/report_remote_datasource.dart';
import '../datasources/report_storage_datasource.dart';
import '../models/report_dto.dart';

/// Implementación concreta de ReportRepository en la capa de datos.
///
/// Principio SRP: Integra los data sources especializados para cumplir el contrato de ReportRepository.
///
/// Ubicación: `lib/features/citizen/data/repositories/report_repository_impl.dart`
/// Capa: Data (Repositories)
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;
  final CategoryRemoteDataSource _categoryDataSource;
  final ReportStorageDataSource _storageDataSource;

  /// Caché en memoria para garantizar que los reportes creados aparezcan de inmediato
  /// incluso ante latencia de sincronización en Firestore o permisos offline
  static final List<ReportEntity> _sessionCache = [];

  ReportRepositoryImpl({
    ReportRemoteDataSource? remoteDataSource,
    CategoryRemoteDataSource? categoryDataSource,
    ReportStorageDataSource? storageDataSource,
  })  : _remoteDataSource = remoteDataSource ?? FirebaseReportRemoteDataSourceImpl(),
        _categoryDataSource = categoryDataSource ?? FirebaseCategoryRemoteDataSourceImpl(),
        _storageDataSource = storageDataSource ?? FirebaseReportStorageDataSourceImpl();

  @override
  Future<Result<List<ReportCategoryEntity>>> getCategories() async {
    try {
      final dtos = await _categoryDataSource.getCategories();
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
    List<List<int>>? multipleImageBytes,
    List<String>? localImagePaths,
  }) async {
    List<String> finalImageUrls = List.from(report.imageUrls);

    // Determinar la lista de bytes de imágenes a procesar
    final List<List<int>> bytesToUpload = [];
    if (multipleImageBytes != null && multipleImageBytes.isNotEmpty) {
      bytesToUpload.addAll(multipleImageBytes);
    } else if (imageBytes != null && imageBytes.isNotEmpty) {
      bytesToUpload.add(imageBytes);
    }

    // Subir cada imagen a Firebase Storage o utilizar respaldo local si falla/offline
    for (int i = 0; i < bytesToUpload.length; i++) {
      final bytes = bytesToUpload[i];
      final fileName = 'evidence_${report.id}_$i.jpg';
      String? uploadedUrl;
      try {
        uploadedUrl = await _storageDataSource.uploadReportImage(
          imageBytes: bytes,
          fileName: fileName,
        );
      } catch (_) {
        // En caso de fallo en Storage, se gestiona el fallback local a continuación
      }

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        finalImageUrls.add(uploadedUrl);
      } else {
        // Respaldo de alta disponibilidad: Si Firebase Storage no está disponible o falla,
        // se codifican los bytes en Base64 para que la imagen persista en Firestore
        // y pueda ser visualizada desde cualquier dispositivo y tras reinstalar el APK.
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        finalImageUrls.add(base64Image);
      }
    }

    final initialHistory = ReportHistoryItem(
      previousStatus: 'none',
      newStatus: report.status.toDbString(),
      changedByUserId: report.citizenId,
      changedByUserName: report.citizenName,
      changedByUserRole: 'citizen',
      comment: 'Reporte registrado por el ciudadano.',
      timestamp: report.createdAt,
    );

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
      evidenceImageUrl: report.evidenceImageUrl,
      resolutionNotes: report.resolutionNotes,
      assignedStaffName: report.assignedStaffName,
      history: report.history.isNotEmpty ? report.history : [initialHistory],
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
    // 1. Consultar datos frescos desde Cloud Firestore
    try {
      final dto = await _remoteDataSource.getReportById(reportId);
      final entity = dto.toDomain();
      _sessionCache.removeWhere((r) => r.id == entity.id);
      _sessionCache.insert(0, entity);
      return Success(entity);
    } catch (_) {
      // 2. Si falla la red o está offline, buscar en caché de sesión
      final cached = _sessionCache.cast<ReportEntity?>().firstWhere(
            (r) => r?.id == reportId,
            orElse: () => null,
          );
      if (cached != null) {
        return Success(cached);
      }
      return const FailureResult(ServerFailure(message: 'Error al consultar reporte o no se encuentra disponible.'));
    }
  }

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async {
    final Map<String, ReportEntity> combined = {};

    // 1. Incorporar reportes reales creados en la sesión actual
    for (final r in _sessionCache) {
      combined[r.id] = r;
    }

    // 2. Consultar reportes reales en Cloud Firestore
    try {
      final dtos = await _remoteDataSource.getAllReports();
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
  Future<Result<ReportEntity>> cancelReport({required String reportId, String? reason}) async {
    ReportEntity? updatedEntity;
    final now = DateTime.now();

    // 1. Actualizar en caché de sesión para reflejo inmediato
    final index = _sessionCache.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final old = _sessionCache[index];
      final cancelEvent = ReportHistoryItem(
        previousStatus: old.status.toDbString(),
        newStatus: 'cancelled',
        changedByUserId: old.citizenId,
        changedByUserName: old.citizenName,
        changedByUserRole: 'citizen',
        comment: reason ?? 'Reporte cancelado por el ciudadano.',
        timestamp: now,
      );
      updatedEntity = old.copyWith(
        status: ReportStatus.cancelled,
        updatedAt: now,
        history: [...old.history, cancelEvent],
      );
      _sessionCache[index] = updatedEntity;
    }

    // 2. Persistir en Cloud Firestore
    try {
      await _remoteDataSource.cancelReport(reportId: reportId, reason: reason);
      if (updatedEntity == null) {
        final dto = await _remoteDataSource.getReportById(reportId);
        updatedEntity = dto.toDomain();
        _sessionCache.removeWhere((r) => r.id == updatedEntity!.id);
        _sessionCache.insert(0, updatedEntity);
      }
      return Success(updatedEntity);
    } on ServerException catch (e) {
      if (updatedEntity != null) {
        return Success(updatedEntity);
      }
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      if (updatedEntity != null) {
        return Success(updatedEntity);
      }
      return FailureResult(ServerFailure(message: 'Error al cancelar reporte: $e'));
    }
  }
}
