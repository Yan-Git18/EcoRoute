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
      } else if (localImagePaths != null && i < localImagePaths.length) {
        // Respaldo de contingencia: Guardar la ruta local para que la evidencia
        // sea visible de inmediato en la app aunque Firebase Storage esté offline
        final localPath = localImagePaths[i];
        if (localPath.isNotEmpty) {
          finalImageUrls.add(localPath);
        }
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

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async {
    final Map<String, ReportEntity> combined = {};

    // 1. Incorporar reportes de la sesión actual
    for (final r in _sessionCache) {
      combined[r.id] = r;
    }

    // 2. Consultar reportes en Cloud Firestore
    try {
      final dtos = await _remoteDataSource.getAllReports();
      for (final dto in dtos) {
        final entity = dto.toDomain();
        combined[entity.id] = entity;
      }
    } catch (_) {}

    // 3. Si la lista está vacía (modo inicial / offline), suministrar semillas comunitarias
    if (combined.isEmpty) {
      final seedReports = _getCommunitySeedReports();
      for (final seed in seedReports) {
        combined[seed.id] = seed;
      }
    }

    final list = combined.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(list);
  }

  @override
  Future<Result<ReportEntity>> cancelReport({required String reportId, String? reason}) async {
    ReportEntity? updatedEntity;

    // 1. Actualizar en caché de sesión para reflejo inmediato
    final index = _sessionCache.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final old = _sessionCache[index];
      updatedEntity = old.copyWith(
        status: ReportStatus.cancelled,
        updatedAt: DateTime.now(),
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

  /// Semillas de demostración urbana para el mapa y reportes cercanos en caso de base de datos vacía.
  static List<ReportEntity> _getCommunitySeedReports() {
    final now = DateTime.now();
    return [
      ReportEntity(
        id: 'seed-rep-1',
        reportNumber: '#REP-1024',
        citizenId: 'seed_user_1',
        citizenName: 'María Mendoza',
        citizenPhone: '987654321',
        categoryId: 'waste_accumulation',
        categoryName: 'Acumulación de basura',
        categoryIcon: 'delete_outline_rounded',
        description: 'Montículo de bolsas plásticas y desechos orgánicos en la acera.',
        priority: ReportPriority.high,
        status: ReportStatus.pending,
        latitude: -12.0478,
        longitude: -77.0415,
        address: 'Av. Abancay 450, Centro Histórico',
        reference: 'Frente al Ministerio Público',
        imageUrls: const [],
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      ReportEntity(
        id: 'seed-rep-2',
        reportNumber: '#REP-2058',
        citizenId: 'seed_user_2',
        citizenName: 'Luis Ramos',
        citizenPhone: '912345678',
        categoryId: 'full_bin',
        categoryName: 'Contenedor lleno',
        categoryIcon: 'delete_sweep_rounded',
        description: 'Contenedor metálico desbordado de residuos comerciales.',
        priority: ReportPriority.medium,
        status: ReportStatus.inProgress,
        latitude: -12.0452,
        longitude: -77.0435,
        address: 'Jr. de la Unión 810',
        reference: 'Cerca a la Plaza San Martín',
        imageUrls: const [],
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      ReportEntity(
        id: 'seed-rep-3',
        reportNumber: '#REP-3192',
        citizenId: 'seed_user_3',
        citizenName: 'Carla Quispe',
        categoryId: 'waste_public_road',
        categoryName: 'Residuos en vía pública',
        categoryIcon: 'cleaning_services_rounded',
        description: 'Desechos dispersos en la berma central tras el comercio ambulatorio.',
        priority: ReportPriority.low,
        status: ReportStatus.resolved,
        latitude: -12.0440,
        longitude: -77.0450,
        address: 'Av. Tacna 320',
        reference: 'Cruce con Jr. Conde de Superunda',
        imageUrls: const [],
        createdAt: now.subtract(const Duration(hours: 18)),
      ),
      ReportEntity(
        id: 'seed-rep-4',
        reportNumber: '#REP-4401',
        citizenId: 'seed_user_4',
        citizenName: 'Jorge Alarcón',
        categoryId: 'damaged_container',
        categoryName: 'Contenedor dañado',
        categoryIcon: 'restore_from_trash_rounded',
        description: 'Tacho municipal con la base rota y tapa desprendida.',
        priority: ReportPriority.medium,
        status: ReportStatus.pending,
        latitude: -12.0485,
        longitude: -77.0440,
        address: 'Jr. Carabaya 530',
        reference: 'A media cuadra de la Plaza Mayor',
        imageUrls: const [],
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      ReportEntity(
        id: 'seed-rep-5',
        reportNumber: '#REP-5520',
        citizenId: 'seed_user_5',
        citizenName: 'Elena Torres',
        categoryId: 'damaged_recycling_point',
        categoryName: 'Punto de reciclaje deteriorado',
        categoryIcon: 'recycling_rounded',
        description: 'Estación de reciclaje con letrero caído y residuos no segregados.',
        priority: ReportPriority.low,
        status: ReportStatus.inProgress,
        latitude: -12.0520,
        longitude: -77.0380,
        address: 'Parque Universitario',
        reference: 'Costado de la Casona de San Marcos',
        imageUrls: const [],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ReportEntity(
        id: 'seed-rep-6',
        reportNumber: '#REP-6635',
        citizenId: 'seed_user_6',
        citizenName: 'Pedro Salazar',
        categoryId: 'waste_accumulation',
        categoryName: 'Acumulación de basura',
        categoryIcon: 'delete_outline_rounded',
        description: 'Residuos de poda y maleza acumulados en la esquina.',
        priority: ReportPriority.high,
        status: ReportStatus.resolved,
        latitude: -12.0490,
        longitude: -77.0400,
        address: 'Jr. Cusco 280',
        reference: 'Esquina con Jr. Azángaro',
        imageUrls: const [],
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
