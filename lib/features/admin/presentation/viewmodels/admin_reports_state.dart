import '../../../citizen/domain/entities/report_entity.dart';
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
  final List<ReportEntity> reports;
  final List<MunicipalCrewEntity> crews;
  final AdminReportFilter selectedFilter;
  final String searchQuery;
  final String? errorMessage;
  final bool isAssigning;

  const AdminReportsState({
    this.isLoading = false,
    this.reports = const [],
    this.crews = const [],
    this.selectedFilter = AdminReportFilter.all,
    this.searchQuery = '',
    this.errorMessage,
    this.isAssigning = false,
  });

  int get totalCount => reports.length;
  int get pendingCount => reports.where((r) => r.status == ReportStatus.pending).length;
  int get assignedCount => reports.where((r) => r.status == ReportStatus.assigned).length;
  int get inProgressCount => reports.where((r) => r.status == ReportStatus.inProgress).length;
  int get resolvedCount => reports.where((r) => r.status == ReportStatus.resolved).length;

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
            (r.assignedToTeamName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return list;
  }

  AdminReportsState copyWith({
    bool? isLoading,
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
      reports: reports ?? this.reports,
      crews: crews ?? this.crews,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isAssigning: isAssigning ?? this.isAssigning,
    );
  }
}
