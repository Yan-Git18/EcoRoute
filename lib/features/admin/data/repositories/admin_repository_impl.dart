import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

/// Implementación del repositorio de administración municipal.
///
/// Principio SRP: Integra el data source de Firestore con una caché en memoria
/// reactiva para garantizar actualizaciones instantáneas en la UI.
class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  static final Map<String, ReportEntity> _adminReportsCache = {};

  AdminRepositoryImpl({AdminRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? FirebaseAdminRemoteDataSourceImpl();

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async {
    final Map<String, ReportEntity> combined = Map.from(_adminReportsCache);

    try {
      final dtos = await _remoteDataSource.getAllReports();
      for (final dto in dtos) {
        final entity = dto.toDomain();
        // Si no está en caché con estado local más reciente, registrar
        if (!combined.containsKey(entity.id)) {
          combined[entity.id] = entity;
          _adminReportsCache[entity.id] = entity;
        }
      }
    } catch (_) {}

    // Semillas si no hay datos en Firestore
    if (combined.isEmpty) {
      final seeds = _getSeedReports();
      for (final s in seeds) {
        combined[s.id] = s;
        _adminReportsCache[s.id] = s;
      }
    }

    final list = combined.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(list);
  }

  @override
  Future<Result<List<MunicipalCrewEntity>>> getAvailableCrews() async {
    try {
      final crews = await _remoteDataSource.getAvailableCrews();
      return Success(crews);
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al consultar cuadrillas: $e'));
    }
  }

  @override
  Future<Result<ReportEntity>> assignReportToCrew({
    required String reportId,
    required MunicipalCrewEntity crew,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  }) async {
    try {
      // 1. Intentar actualizar en Firestore
      try {
        await _remoteDataSource.assignReportToCrew(
          reportId: reportId,
          crew: crew,
          adminId: adminId,
          adminName: adminName,
          priority: priority,
          instructions: instructions,
        );
      } catch (_) {
        // En caso de modo offline o sin conexión directa, continuar con actualización local reactiva
      }

      // 2. Actualizar inmediatamente en la caché
      final existing = _adminReportsCache[reportId];
      final updated = (existing ?? _getFallbackReport(reportId)).copyWith(
        status: ReportStatus.assigned,
        priority: priority ?? existing?.priority ?? ReportPriority.medium,
        assignedToTeamId: crew.id,
        assignedToTeamName: crew.name,
        assignedStaffName: crew.leadStaffName,
        assignedVehicle: '${crew.vehicleCode} • ${crew.vehiclePlate}',
        updatedAt: DateTime.now(),
      );

      _adminReportsCache[reportId] = updated;
      return Success(updated);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al asignar reporte: $e'));
    }
  }

  @override
  Future<Result<ReportEntity>> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  }) async {
    try {
      try {
        await _remoteDataSource.updateReportPriority(reportId: reportId, priority: priority);
      } catch (_) {}

      final existing = _adminReportsCache[reportId];
      if (existing != null) {
        final updated = existing.copyWith(priority: priority);
        _adminReportsCache[reportId] = updated;
        return Success(updated);
      }
      return FailureResult(const ServerFailure(message: 'Reporte no encontrado'));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al actualizar prioridad: $e'));
    }
  }

  @override
  Future<Result<List<UserEntity>>> getStaffMembers() async {
    try {
      final list = await _remoteDataSource.getStaffMembers();
      return Success(list);
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al consultar personal: $e'));
    }
  }

  @override
  Future<Result<UserEntity?>> searchUserByExactEmail(String email) async {
    try {
      final user = await _remoteDataSource.searchUserByExactEmail(email);
      return Success(user);
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al buscar usuario: $e'));
    }
  }

  @override
  Future<Result<void>> updateUserRole({
    required String userId,
    required UserRole newRole,
    String? teamId,
  }) async {
    try {
      await _remoteDataSource.updateUserRole(
        userId: userId,
        newRole: newRole,
        teamId: teamId,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al actualizar rol: $e'));
    }
  }

  static ReportEntity _getFallbackReport(String id) {
    return ReportEntity(
      id: id,
      reportNumber: '#REP-0001',
      citizenId: 'cit-1',
      citizenName: 'Vecino Ciudadano',
      categoryId: 'waste',
      categoryName: 'Acumulación de basura',
      categoryIcon: 'delete_outline_rounded',
      description: 'Reporte de acumulación en acera.',
      priority: ReportPriority.high,
      status: ReportStatus.assigned,
      latitude: -12.046,
      longitude: -77.042,
      address: 'Av. Los Próceres 452',
      imageUrls: const [],
      createdAt: DateTime.now(),
    );
  }

  static List<ReportEntity> _getSeedReports() {
    final now = DateTime.now();
    return [
      ReportEntity(
        id: 'seed-rep-1',
        reportNumber: '#REP-1024',
        citizenId: 'c-1',
        citizenName: 'María Mendoza',
        citizenPhone: '987 654 321',
        categoryId: 'waste_accumulation',
        categoryName: 'Acumulación de basura',
        categoryIcon: 'delete_outline_rounded',
        description: 'Montículo de bolsas y desechos orgánicos en la acera frente al mercado.',
        priority: ReportPriority.high,
        status: ReportStatus.pending,
        latitude: -12.0478,
        longitude: -77.0415,
        address: 'Av. Abancay 450, Centro Histórico',
        reference: 'Frente al Ministerio Público',
        imageUrls: const [],
        createdAt: now.subtract(const Duration(minutes: 45)),
      ),
      ReportEntity(
        id: 'seed-rep-2',
        reportNumber: '#REP-2058',
        citizenId: 'c-2',
        citizenName: 'Luis Ramos',
        citizenPhone: '912 345 678',
        categoryId: 'full_bin',
        categoryName: 'Contenedor lleno',
        categoryIcon: 'delete_sweep_rounded',
        description: 'Contenedor metálico desbordado de residuos comerciales en la peatonal.',
        priority: ReportPriority.medium,
        status: ReportStatus.inProgress,
        latitude: -12.0452,
        longitude: -77.0435,
        address: 'Jr. de la Unión 810',
        reference: 'Cerca a la Plaza San Martín',
        imageUrls: const [],
        createdAt: now.subtract(const Duration(hours: 3)),
        assignedToTeamName: 'Cuadrilla Zona Norte',
        assignedVehicle: 'Camión #04 • ECR-882',
      ),
      ReportEntity(
        id: 'seed-rep-3',
        reportNumber: '#REP-3012',
        citizenId: 'c-3',
        citizenName: 'Carla Silva',
        citizenPhone: '998 877 665',
        categoryId: 'debris',
        categoryName: 'Escombros en vía pública',
        categoryIcon: 'construction_rounded',
        description: 'Bolsas de desmonte y restos de construcción bloqueando el paso peatonal.',
        priority: ReportPriority.high,
        status: ReportStatus.pending,
        latitude: -12.0510,
        longitude: -77.0380,
        address: 'Av. Nicolás de Piérola 1240',
        reference: 'Cruce con Jr. Lampa',
        imageUrls: const [],
        createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
      ),
      ReportEntity(
        id: 'seed-rep-4',
        reportNumber: '#REP-4091',
        citizenId: 'c-4',
        citizenName: 'Pedro Quispe',
        citizenPhone: '945 123 789',
        categoryId: 'recycling',
        categoryName: 'Punto de reciclaje saturado',
        categoryIcon: 'recycling_rounded',
        description: 'Estación de segregación de plástico y cartón saturada.',
        priority: ReportPriority.low,
        status: ReportStatus.assigned,
        latitude: -12.0430,
        longitude: -77.0460,
        address: 'Jr. Cailloma 320',
        reference: 'Frente a biblioteca comunal',
        imageUrls: const [],
        createdAt: now.subtract(const Duration(hours: 4)),
        assignedToTeamName: 'Cuadrilla Centro Histórico',
        assignedVehicle: 'Camión #01 • ECR-119',
      ),
      ReportEntity(
        id: 'seed-rep-5',
        reportNumber: '#REP-5002',
        citizenId: 'c-5',
        citizenName: 'Elena Torres',
        citizenPhone: '933 221 100',
        categoryId: 'cleaning',
        categoryName: 'Limpieza de parque completada',
        categoryIcon: 'check_circle_outline_rounded',
        description: 'Limpieza periódica de áreas verdes y retiro de maleza.',
        priority: ReportPriority.low,
        status: ReportStatus.resolved,
        latitude: -12.0490,
        longitude: -77.0420,
        address: 'Parque Universitario',
        reference: 'Sector fuente central',
        imageUrls: const [],
        createdAt: now.subtract(const Duration(days: 1)),
        assignedToTeamName: 'Cuadrilla Especial Desbordes',
        assignedVehicle: 'Camión #05 • ECR-554',
      ),
    ];
  }
}
