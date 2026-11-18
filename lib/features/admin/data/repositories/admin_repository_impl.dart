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
  static final Map<String, MunicipalCrewEntity> _adminCrewsCache = {};

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

    final list = combined.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(list);
  }

  @override
  Future<Result<List<MunicipalCrewEntity>>> getAvailableCrews() async {
    try {
      final dtos = await _remoteDataSource.getAvailableCrews();
      for (final dto in dtos) {
        final entity = dto.toDomain();
        _adminCrewsCache[entity.id] = entity;
      }
      return Success(_adminCrewsCache.values.toList());
    } catch (e) {
      if (_adminCrewsCache.isNotEmpty) {
        return Success(_adminCrewsCache.values.toList());
      }
      return FailureResult(ServerFailure(message: 'Error al consultar cuadrillas: $e'));
    }
  }

  @override
  Future<Result<MunicipalCrewEntity>> createCrew(MunicipalCrewEntity crew) async {
    try {
      final dto = await _remoteDataSource.createCrew(crew);
      final entity = dto.toDomain();
      _adminCrewsCache[entity.id] = entity;
      return Success(entity);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al registrar cuadrilla: $e'));
    }
  }

  @override
  Future<Result<MunicipalCrewEntity>> updateCrew(MunicipalCrewEntity crew) async {
    try {
      await _remoteDataSource.updateCrew(crew);
      _adminCrewsCache[crew.id] = crew;
      return Success(crew);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al actualizar cuadrilla: $e'));
    }
  }

  @override
  Future<Result<void>> deleteCrew(String crewId) async {
    try {
      await _remoteDataSource.deleteCrew(crewId);
      _adminCrewsCache.remove(crewId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al eliminar cuadrilla: $e'));
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
      if (existing == null) {
        return const FailureResult(ServerFailure(message: 'Reporte no encontrado'));
      }
      final updated = existing.copyWith(
        status: ReportStatus.assigned,
        priority: priority ?? existing.priority,
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
      return const FailureResult(ServerFailure(message: 'Reporte no encontrado'));
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
}
