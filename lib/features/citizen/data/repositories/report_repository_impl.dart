import 'dart:typed_data';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/image_compression.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/report_category_entity.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/category_remote_datasource.dart';
import '../datasources/report_remote_datasource.dart';
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

  /// Caché en memoria para garantizar que los reportes creados aparezcan de inmediato
  /// incluso ante latencia de sincronización en Firestore o permisos offline
  static final List<ReportEntity> _sessionCache = [];

  ReportRepositoryImpl({
    ReportRemoteDataSource? remoteDataSource,
    CategoryRemoteDataSource? categoryDataSource,
  })  : _remoteDataSource = remoteDataSource ?? FirebaseReportRemoteDataSourceImpl(),
        _categoryDataSource = categoryDataSource ?? FirebaseCategoryRemoteDataSourceImpl();

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
    List<List<int>>? multipleImageBytes,
  }) async {
    final originals = multipleImageBytes?.isNotEmpty == true
        ? multipleImageBytes!
        : [if (imageBytes != null && imageBytes.isNotEmpty) imageBytes];
    if (originals.length > ReportEntity.maxPhotos) {
      return const FailureResult(ValidationFailure(message: 'Adjunta hasta 4 fotografías.'));
    }
    try {
      final photos = <Uint8List>[];
      for (final bytes in originals) {
        photos.add(await compressPhoto(bytes, PhotoSize.report));
      }
      final savedDto = await _remoteDataSource.createReport(
        ReportDto.fromDomain(report),
        photos: photos,
      );
      final domainReport = savedDto.toDomain();
      _sessionCache.removeWhere((r) => r.id == domainReport.id);
      _sessionCache.insert(0, domainReport);
      return Success(domainReport);
    } on PhotoCompressionException catch (error) {
      return FailureResult(ValidationFailure(message: error.message));
    } on ServerException catch (error) {
      return FailureResult(ServerFailure(message: error.message, code: error.code));
    } catch (_) {
      return const FailureResult(ServerFailure(message: 'No se pudo guardar el reporte.'));
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
