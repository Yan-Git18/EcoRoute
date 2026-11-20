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
      return Success(savedDto.toDomain());
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
    try {
      final dtos = await _remoteDataSource.getMyReports(citizenId);
      return Success(dtos.map((dto) => dto.toDomain()).toList());
    } on ServerException catch (error) {
      return FailureResult(ServerFailure(message: error.message, code: error.code));
    }
  }

  @override
  Future<Result<ReportEntity>> getReportById(String reportId) async {
    try {
      final dto = await _remoteDataSource.getReportById(reportId);
      return Success(dto.toDomain());
    } on ServerException catch (error) {
      return FailureResult(ServerFailure(message: error.message, code: error.code));
    }
  }

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async {
    try {
      final dtos = await _remoteDataSource.getAllReports();
      return Success(dtos.map((dto) => dto.toDomain()).toList());
    } on ServerException catch (error) {
      return FailureResult(ServerFailure(message: error.message, code: error.code));
    }
  }

  @override
  Future<Result<ReportEntity>> cancelReport({required String reportId, String? reason}) async {
    try {
      await _remoteDataSource.cancelReport(reportId: reportId, reason: reason);
      return getReportById(reportId);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    }
  }
}
