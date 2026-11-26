import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/geo/cajamarca_urban_zones.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/admin_report_page.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/usecases/create_crew_use_case.dart';
import '../../domain/usecases/delete_crew_use_case.dart';
import '../../domain/usecases/get_crews_use_case.dart';
import '../../domain/usecases/get_urban_reports_use_case.dart';
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

final urbanReportsProvider =
    FutureProvider.autoDispose<Map<CajamarcaZone, List<ReportEntity>>>((ref) {
      return GetUrbanReportsUseCase(ref.watch(adminRepositoryProvider))();
    });

final adminTeamStaffProvider = FutureProvider.autoDispose<List<UserEntity>>((ref) async {
  final result = await ref.watch(adminRepositoryProvider).getStaffMembers();
  return result.fold(onSuccess: (staff) => staff, onFailure: (failure) => throw failure.message);
});

final adminBusyStaffProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final result = await ref.watch(adminRepositoryProvider).getBusyStaffIds();
  return result.fold(onSuccess: (staff) => staff, onFailure: (failure) => throw failure.message);
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
    NotifierProvider.autoDispose<AdminReportsViewModel, AdminReportsState>(() {
      return AdminReportsViewModel();
    });

// --- Notifier / ViewModel ---

class AdminReportsViewModel extends Notifier<AdminReportsState> {
  late AdminRepository _repository;
  late GetCrewsUseCase _getCrewsUseCase;
  late CreateCrewUseCase _createCrewUseCase;
  late UpdateCrewUseCase _updateCrewUseCase;
  late DeleteCrewUseCase _deleteCrewUseCase;
  Future<void>? _activeLoad;
  int _buildGeneration = 0;
  int _dataRevision = 0;
  int _pageGeneration = 0;

  @override
  AdminReportsState build() {
    final buildGeneration = ++_buildGeneration;
    _pageGeneration++;
    _activeLoad = null;
    _repository = ref.watch(adminRepositoryProvider);
    _getCrewsUseCase = ref.watch(getCrewsUseCaseProvider);
    _createCrewUseCase = ref.watch(createCrewUseCaseProvider);
    _updateCrewUseCase = ref.watch(updateCrewUseCaseProvider);
    _deleteCrewUseCase = ref.watch(deleteCrewUseCaseProvider);

    // Carga inicial asíncrona
    Future.microtask(() async {
      if (_isCurrentBuild(buildGeneration)) await refresh();
    });
    return const AdminReportsState(isLoading: true);
  }

  bool _isCurrentBuild(int generation) =>
      generation == _buildGeneration && ref.mounted;

  Future<void> _loadReports() async {
    final generation = ++_pageGeneration;
    state = state.copyWith(isLoading: true, isLoadingMore: false, loadMoreFailed: false);

    late Result<AdminReportPage<ReportEntity>> reportsResult;
    late Result<List<MunicipalCrewEntity>> crewsResult;
    late Result<AdminReportTotals> totalsResult;
    int revision;
    // Si se guardó un cambio durante la consulta, vuelve a leer antes de publicar.
    do {
      revision = _dataRevision;
      (reportsResult, crewsResult, totalsResult) = await (
        _repository.getReportsPage(),
        _getCrewsUseCase(),
        _repository.getReportTotals(),
      ).wait;
      if (generation != _pageGeneration || !ref.mounted) return;
    } while (revision != _dataRevision);

    final page = reportsResult.dataOrNull;
    state = state.copyWith(
      isLoading: false,
      reports: page?.items,
      nextCursor: page?.nextCursor,
      clearNextCursor: page != null && page.nextCursor == null,
      crews: crewsResult.dataOrNull,
      totals: totalsResult.dataOrNull,
      totalsLoadFailed: totalsResult.isFailure,
      hasLoadedReports: state.hasLoadedReports || reportsResult.isSuccess,
      hasLoadedCrews: state.hasLoadedCrews || crewsResult.isSuccess,
      reportsLoadFailed: reportsResult.isFailure,
      crewsLoadFailed: crewsResult.isFailure,
    );
  }

  Future<void> loadMoreReports() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.isLoading || state.isLoadingMore) return;

    final generation = _pageGeneration;
    state = state.copyWith(isLoadingMore: true, loadMoreFailed: false);
    late Result<AdminReportPage<ReportEntity>> result;
    int revision;
    do {
      revision = _dataRevision;
      result = await _repository.getReportsPage(after: cursor);
      if (generation != _pageGeneration || !ref.mounted) return;
    } while (revision != _dataRevision);

    final page = result.dataOrNull;
    if (page == null) {
      state = state.copyWith(isLoadingMore: false, loadMoreFailed: true);
      return;
    }

    final seen = state.reports.map((report) => report.id).toSet();
    state = state.copyWith(
      isLoadingMore: false,
      reports: [...state.reports, ...page.items.where((report) => seen.add(report.id))],
      nextCursor: page.nextCursor,
      clearNextCursor: page.nextCursor == null,
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
    MunicipalCrewEntity? crew,
    List<String> staffIds = const [],
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  }) async {
    if (state.isAssigning || (crew == null) == staffIds.isEmpty) return false;
    state = state.copyWith(isAssigning: true, clearError: true);
    final buildGeneration = _buildGeneration;

    final result = crew == null
        ? await _repository.assignReportToStaff(
            reportId: reportId,
            staffIds: staffIds,
            adminId: adminId,
            adminName: adminName,
            priority: priority,
            instructions: instructions,
          )
        : await _repository.assignReportToCrew(
            reportId: reportId,
            crew: crew,
            adminId: adminId,
            adminName: adminName,
            priority: priority,
            instructions: instructions,
          );
    if (!_isCurrentBuild(buildGeneration)) return false;

    switch (result) {
      case Success(data: final updatedReport):
        _dataRevision++;
        ref.invalidate(urbanReportsProvider);
        final updatedReports = state.reports.map((r) {
          return r.id == updatedReport.id ? updatedReport : r;
        }).toList();

        state = state.copyWith(
          isAssigning: false,
          reports: updatedReports,
          crews: crew == null
              ? null
              : [
                  for (final team in state.crews)
                    if (team.id == crew.id)
                      team.copyWith(
                        status: MunicipalCrewStatus.onRoute,
                        activeTasksCount: 1,
                      )
                    else
                      team,
                ],
        );
        if (_activeLoad == null) unawaited(_refreshResources(includeTotals: true));
        return true;

      case FailureResult(failure: final f):
        state = state.copyWith(isAssigning: false, errorMessage: f.message);
        return false;
    }
  }

  Future<void> _refreshResources({bool includeTotals = false}) async {
    final revision = _dataRevision;
    final generation = _pageGeneration;
    final totalsRequest = includeTotals ? _repository.getReportTotals() : null;
    final crews = await _getCrewsUseCase();
    final totals = await totalsRequest;
    if (!ref.mounted || revision != _dataRevision || generation != _pageGeneration) return;
    state = state.copyWith(
      crews: crews.dataOrNull,
      hasLoadedCrews: state.hasLoadedCrews || crews.isSuccess,
      crewsLoadFailed: crews.isFailure,
      totals: totals?.dataOrNull,
      totalsLoadFailed: totals?.isFailure,
    );
  }

  Future<void> updatePriority(String reportId, ReportPriority priority) async {
    final buildGeneration = _buildGeneration;
    final result = await _repository.updateReportPriority(reportId: reportId, priority: priority);
    if (!_isCurrentBuild(buildGeneration)) return;

    if (result is Success<ReportEntity>) {
      _dataRevision++;
      ref.invalidate(urbanReportsProvider);
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
    String? vehicleType,
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
      vehicleType: vehicleType,
    );

    return saveCrew(updated);
  }

  Future<bool> saveCrew(MunicipalCrewEntity updated) async {
    final buildGeneration = _buildGeneration;
    final result = await _updateCrewUseCase.call(updated);
    if (!_isCurrentBuild(buildGeneration)) return false;
    switch (result) {
      case Success(data: final savedCrew):
        _dataRevision++;
        final newCrews = state.crews.map((crew) {
          return crew.id == updated.id && crew.vehicleOnly == updated.vehicleOnly
              ? savedCrew
              : crew;
        }).toList();
        state = state.copyWith(crews: newCrews, clearError: true);
        await _refreshResources();
        return true;
      case FailureResult(failure: final f):
        state = state.copyWith(errorMessage: f.message);
        return false;
    }
  }

  Future<bool> createCrew(MunicipalCrewEntity crew) async {
    final buildGeneration = _buildGeneration;
    final result = await _createCrewUseCase.call(crew);
    if (!_isCurrentBuild(buildGeneration)) return false;
    switch (result) {
      case Success(data: final created):
        _dataRevision++;
        final filtered = state.crews
            .where((c) => c.id != created.id || c.vehicleOnly != created.vehicleOnly)
            .toList();
        state = state.copyWith(crews: [created, ...filtered], clearError: true);
        await _refreshResources();
        return true;
      case FailureResult(failure: final f):
        state = state.copyWith(errorMessage: f.message);
        return false;
    }
  }

  Future<bool> deleteCrew(String crewId) async {
    return _removeResource(crewId, false, _deleteCrewUseCase.call(crewId));
  }

  Future<bool> deleteVehicle(String vehicleId) {
    final repository = ref.read(adminRepositoryProvider);
    return _removeResource(vehicleId, true, repository.deleteVehicle(vehicleId));
  }

  Future<bool> _removeResource(
    String id,
    bool vehicleOnly,
    Future<Result<void>> deletion,
  ) async {
    final buildGeneration = _buildGeneration;
    final result = await deletion;
    if (!_isCurrentBuild(buildGeneration)) return false;
    switch (result) {
      case Success():
        _dataRevision++;
        state = state.copyWith(
          crews: state.crews.where((c) => c.id != id || c.vehicleOnly != vehicleOnly).toList(),
          clearError: true,
        );
        await _refreshResources();
        return true;
      case FailureResult(failure: final f):
        state = state.copyWith(errorMessage: f.message);
        return false;
    }
  }

  Future<void> refresh() {
    if (_activeLoad case final pending?) return pending;
    late final Future<void> load;
    load = _loadReports().whenComplete(() {
      if (identical(_activeLoad, load)) _activeLoad = null;
    });
    return _activeLoad = load;
  }
}
