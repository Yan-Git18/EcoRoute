import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/usecases/create_crew_use_case.dart';
import '../../domain/usecases/delete_crew_use_case.dart';
import '../../domain/usecases/get_crews_use_case.dart';
import '../../domain/usecases/update_crew_use_case.dart';
import 'admin_reports_state.dart';

// --- Inyección de Dependencias con Riverpod ---

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return FirebaseAdminRemoteDataSourceImpl();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return AdminRepositoryImpl(remoteDataSource: dataSource);
});

final getCrewsUseCaseProvider = Provider<GetCrewsUseCase>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return GetCrewsUseCase(repo);
});

final createCrewUseCaseProvider = Provider<CreateCrewUseCase>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return CreateCrewUseCase(repo);
});

final updateCrewUseCaseProvider = Provider<UpdateCrewUseCase>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return UpdateCrewUseCase(repo);
});

final deleteCrewUseCaseProvider = Provider<DeleteCrewUseCase>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return DeleteCrewUseCase(repo);
});

final adminReportsViewModelProvider =
    NotifierProvider<AdminReportsViewModel, AdminReportsState>(() {
  return AdminReportsViewModel();
});

// --- Notifier / ViewModel ---

class AdminReportsViewModel extends Notifier<AdminReportsState> {
  late final AdminRepository _repository;
  late final GetCrewsUseCase _getCrewsUseCase;
  late final CreateCrewUseCase _createCrewUseCase;
  late final UpdateCrewUseCase _updateCrewUseCase;
  late final DeleteCrewUseCase _deleteCrewUseCase;

  @override
  AdminReportsState build() {
    _repository = ref.watch(adminRepositoryProvider);
    _getCrewsUseCase = ref.watch(getCrewsUseCaseProvider);
    _createCrewUseCase = ref.watch(createCrewUseCaseProvider);
    _updateCrewUseCase = ref.watch(updateCrewUseCaseProvider);
    _deleteCrewUseCase = ref.watch(deleteCrewUseCaseProvider);

    // Carga inicial asíncrona
    Future.microtask(() => loadReports());
    return const AdminReportsState(isLoading: true);
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final reportsResult = await _repository.getAllReports();
    final crewsResult = await _getCrewsUseCase();

    final List<ReportEntity> reports = switch (reportsResult) {
      Success(data: final list) => list,
      FailureResult() => state.reports,
    };

    final List<MunicipalCrewEntity> crews = switch (crewsResult) {
      Success(data: final list) => List<MunicipalCrewEntity>.from(list),
      FailureResult() => state.crews,
    };

    state = state.copyWith(
      isLoading: false,
      reports: reports,
      crews: crews,
    );
  }

  void setFilter(AdminReportFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> assignReport({
    required String reportId,
    required MunicipalCrewEntity crew,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  }) async {
    state = state.copyWith(isAssigning: true, clearError: true);

    final result = await _repository.assignReportToCrew(
      reportId: reportId,
      crew: crew,
      adminId: adminId,
      adminName: adminName,
      priority: priority,
      instructions: instructions,
    );

    switch (result) {
      case Success(data: final updatedReport):
        final updatedReports = state.reports.map((r) {
          return r.id == updatedReport.id ? updatedReport : r;
        }).toList();

        state = state.copyWith(
          isAssigning: false,
          reports: updatedReports,
        );
        return true;

      case FailureResult(failure: final f):
        state = state.copyWith(
          isAssigning: false,
          errorMessage: f.message,
        );
        return false;
    }
  }

  Future<void> updatePriority(String reportId, ReportPriority priority) async {
    final result = await _repository.updateReportPriority(
      reportId: reportId,
      priority: priority,
    );

    if (result is Success<ReportEntity>) {
      final updatedReport = result.data;
      final updatedReports = state.reports.map((r) {
        return r.id == updatedReport.id ? updatedReport : r;
      }).toList();

      state = state.copyWith(reports: updatedReports);
    }
  }

  Future<bool> updateCrew({
    required String crewId,
    MunicipalCrewStatus? status,
    String? zone,
    bool? isAvailable,
    String? leadStaffName,
    String? vehicleCode,
    String? vehiclePlate,
  }) async {
    final existingIndex = state.crews.indexWhere((c) => c.id == crewId);
    if (existingIndex < 0) return false;

    final existing = state.crews[existingIndex];
    final updated = existing.copyWith(
      status: status ?? existing.status,
      zone: zone ?? existing.zone,
      isAvailable: isAvailable ?? existing.isAvailable,
      leadStaffName: leadStaffName ?? existing.leadStaffName,
      vehicleCode: vehicleCode ?? existing.vehicleCode,
      vehiclePlate: vehiclePlate ?? existing.vehiclePlate,
    );

    final result = await _updateCrewUseCase.call(updated);
    switch (result) {
      case Success(data: final savedCrew):
        final newCrews = List<MunicipalCrewEntity>.from(state.crews);
        newCrews[existingIndex] = savedCrew;
        state = state.copyWith(crews: newCrews);
        return true;
      case FailureResult(failure: final f):
        state = state.copyWith(errorMessage: f.message);
        return false;
    }
  }

  Future<bool> createCrew(MunicipalCrewEntity crew) async {
    final result = await _createCrewUseCase.call(crew);
    switch (result) {
      case Success(data: final created):
        final filtered = state.crews.where((c) => c.id != created.id).toList();
        state = state.copyWith(crews: [created, ...filtered]);
        return true;
      case FailureResult(failure: final f):
        state = state.copyWith(errorMessage: f.message);
        return false;
    }
  }

  Future<bool> deleteCrew(String crewId) async {
    final result = await _deleteCrewUseCase.call(crewId);
    switch (result) {
      case Success():
        state = state.copyWith(
          crews: state.crews.where((c) => c.id != crewId).toList(),
        );
        return true;
      case FailureResult(failure: final f):
        state = state.copyWith(errorMessage: f.message);
        return false;
    }
  }

  Future<void> refresh() async {
    await loadReports();
  }
}
