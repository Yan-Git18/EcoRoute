import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/admin_report_page.dart';
import '../../domain/entities/municipal_crew_entity.dart';

/// Opciones de filtrado para la bandeja de administración municipal.
enum AdminReportFilter {
  all('Todos'),
  pending('Pendientes'),
  assigned('Asignados'),
  inProgress('En Proceso'),
  resolved('Resueltos');

  final String label;
  const AdminReportFilter(this.label);
}

/// Estado inmutable de la bandeja de reportes de administración municipal.
class AdminReportsState {
  final bool isLoading;
  final bool hasLoadedReports;
  final bool hasLoadedCrews;
  final bool reportsLoadFailed;
  final bool crewsLoadFailed;
  final bool totalsLoadFailed;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final AdminReportTotals? totals;
  final AdminReportCursor? nextCursor;
  final List<ReportEntity> reports;
  final List<MunicipalCrewEntity> crews;
  final AdminReportFilter selectedFilter;
  final String searchQuery;
  final String? errorMessage;
  final bool isAssigning;

  const AdminReportsState({
    this.isLoading = false,
    this.hasLoadedReports = false,
    this.hasLoadedCrews = false,
    this.reportsLoadFailed = false,
    this.crewsLoadFailed = false,
    this.totalsLoadFailed = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.totals,
    this.nextCursor,
    this.reports = const [],
    this.crews = const [],
    this.selectedFilter = AdminReportFilter.all,
    this.searchQuery = '',
    this.errorMessage,
    this.isAssigning = false,
  });

  List<MunicipalCrewEntity> get teams =>
      crews.where((crew) => !crew.vehicleOnly).toList();

  List<MunicipalCrewEntity> get fleet => crews
      .where(
        (crew) =>
            crew.vehicleOnly ||
            (crew.vehicleId == null && crew.vehiclePlate.trim().isNotEmpty),
      )
      .toList();

  List<ReportEntity> get filteredReports {
    // 1. Filtro por estado
    var list = switch (selectedFilter) {
      AdminReportFilter.all => reports,
      AdminReportFilter.pending => reports.where((r) => r.status == ReportStatus.pending).toList(),
      AdminReportFilter.assigned => reports.where((r) => r.status == ReportStatus.assigned).toList(),
      AdminReportFilter.inProgress => reports.where((r) => r.status == ReportStatus.inProgress).toList(),
      AdminReportFilter.resolved => reports.where((r) => r.status == ReportStatus.resolved).toList(),
    };

    // 2. Filtro por buscador de texto
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) {
        return r.reportNumber.toLowerCase().contains(q) ||
            r.categoryName.toLowerCase().contains(q) ||
            r.address.toLowerCase().contains(q) ||
            r.citizenName.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            (r.assignedToTeamName?.toLowerCase().contains(q) ?? false) ||
            (r.assignedStaffName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return list;
  }

  AdminReportsState copyWith({
    bool? isLoading,
    bool? hasLoadedReports,
    bool? hasLoadedCrews,
    bool? reportsLoadFailed,
    bool? crewsLoadFailed,
    bool? totalsLoadFailed,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    AdminReportTotals? totals,
    AdminReportCursor? nextCursor,
    bool clearNextCursor = false,
    List<ReportEntity>? reports,
    List<MunicipalCrewEntity>? crews,
    AdminReportFilter? selectedFilter,
    String? searchQuery,
    String? errorMessage,
    bool? isAssigning,
    bool clearError = false,
  }) {
    return AdminReportsState(
      isLoading: isLoading ?? this.isLoading,
      hasLoadedReports: hasLoadedReports ?? this.hasLoadedReports,
      hasLoadedCrews: hasLoadedCrews ?? this.hasLoadedCrews,
      reportsLoadFailed: reportsLoadFailed ?? this.reportsLoadFailed,
      crewsLoadFailed: crewsLoadFailed ?? this.crewsLoadFailed,
      totalsLoadFailed: totalsLoadFailed ?? this.totalsLoadFailed,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      totals: totals ?? this.totals,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      reports: reports ?? this.reports,
      crews: crews ?? this.crews,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isAssigning: isAssigning ?? this.isAssigning,
    );
  }
}
