import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/admin_report_page.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

/// Implementación del repositorio de administración municipal.
///
/// Convierte las respuestas de Firestore en resultados de dominio.
class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  AdminRepositoryImpl({AdminRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? FirebaseAdminRemoteDataSourceImpl();

  @override
  Future<Result<AdminReportPage<ReportEntity>>> getReportsPage({AdminReportCursor? after}) async {
    try {
      final page = await _remoteDataSource.getReportsPage(after: after);
      return Success(AdminReportPage(
        page.items.map((dto) => dto.toDomain()).toList(),
        nextCursor: page.nextCursor,
      ));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (_) {
      return const FailureResult(ServerFailure(message: 'No se pudieron consultar los reportes.'));
    }
  }

  @override
  Future<Result<AdminReportTotals>> getReportTotals() async {
    try {
      return Success(await _remoteDataSource.getReportTotals());
    } catch (_) {
      return const FailureResult(ServerFailure(message: 'No se pudieron consultar los totales.'));
    }
  }

  @override
  Future<Result<List<MunicipalCrewEntity>>> getAvailableCrews() async {
    try {
      final dtos = await _remoteDataSource.getAvailableCrews();
      return Success(dtos.map((dto) => dto.toDomain()).toList());
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
    } catch (_) {
      return const FailureResult(ServerFailure(message: 'No se pudieron consultar las cuadrillas.'));
    }
  }

  @override
  Future<Result<MunicipalCrewEntity>> createCrew(MunicipalCrewEntity crew) async {
    try {
      final dto = await _remoteDataSource.createCrew(crew);
      return Success(dto.toDomain());
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
      final saved = await _remoteDataSource.assignReportToCrew(
        reportId: reportId,
        crew: crew,
        adminId: adminId,
        adminName: adminName,
        priority: priority,
        instructions: instructions,
      );
      return Success(saved.toDomain());
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
      final saved = await _remoteDataSource.updateReportPriority(reportId: reportId, priority: priority);
      return Success(saved.toDomain());
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(message: e.message, code: e.code));
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
