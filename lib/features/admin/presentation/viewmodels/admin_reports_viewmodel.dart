import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_reports_state.dart';

// --- Inyección de Dependencias con Riverpod ---

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return FirebaseAdminRemoteDataSourceImpl();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return AdminRepositoryImpl(remoteDataSource: dataSource);
});

final adminReportsViewModelProvider =
    NotifierProvider<AdminReportsViewModel, AdminReportsState>(() {
  return AdminReportsViewModel();
});

// --- Notifier / ViewModel ---

class AdminReportsViewModel extends Notifier<AdminReportsState> {
  late final AdminRepository _repository;

  @override
  AdminReportsState build() {
    _repository = ref.watch(adminRepositoryProvider);
    // Carga inicial asíncrona
    Future.microtask(() => loadReports());
    return const AdminReportsState(isLoading: true);
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final reportsResult = await _repository.getAllReports();
    final crewsResult = await _repository.getAvailableCrews();

    final List<ReportEntity> reports = switch (reportsResult) {
      Success(data: final list) => list,
      FailureResult() => state.reports,
    };

    final List<MunicipalCrewEntity> crews = switch (crewsResult) {
      Success(data: final list) => list,
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

  Future<void> updateCrew({
    required String crewId,
    MunicipalCrewStatus? status,
    String? zone,
    bool? isAvailable,
  }) async {
    final updatedCrews = state.crews.map((c) {
      if (c.id == crewId) {
        return c.copyWith(
          status: status ?? c.status,
          zone: zone ?? c.zone,
          isAvailable: isAvailable ?? c.isAvailable,
        );
      }
      return c;
    }).toList();

    state = state.copyWith(crews: updatedCrews);
  }

  Future<void> refresh() async {
    await loadReports();
  }
}
