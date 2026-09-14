import '../../domain/entities/report_entity.dart';

/// Filtros disponibles para la lista de "Mis reportes".
enum ReportFilter {
  all('Todos'),
  pending('Pendientes'),
  inProgress('En proceso'),
  resolved('Resueltos');

  final String label;
  const ReportFilter(this.label);
}

/// Estado inmutable de la pantalla "Mis reportes".
///
/// Ubicación: `lib/features/citizen/presentation/viewmodels/my_reports_state.dart`
/// Capa: Presentation (ViewModels)
class MyReportsState {
  final List<ReportEntity> reports;
  final ReportFilter selectedFilter;
  final bool isLoading;
  final String? errorMessage;

  const MyReportsState({
    this.reports = const [],
    this.selectedFilter = ReportFilter.all,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Lista filtrada reactivamente según la pestaña seleccionada
  List<ReportEntity> get filteredReports {
    switch (selectedFilter) {
      case ReportFilter.all:
        return reports;
      case ReportFilter.pending:
        return reports
            .where((r) =>
                r.status == ReportStatus.pending ||
                r.status == ReportStatus.assigned)
            .toList();
      case ReportFilter.inProgress:
        return reports
            .where((r) => r.status == ReportStatus.inProgress)
            .toList();
      case ReportFilter.resolved:
        return reports
            .where((r) => r.status == ReportStatus.resolved)
            .toList();
    }
  }

  MyReportsState copyWith({
    List<ReportEntity>? reports,
    ReportFilter? selectedFilter,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyReportsState(
      reports: reports ?? this.reports,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
