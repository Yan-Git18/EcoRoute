import '../../../../core/enums/report_filter.dart';
import '../../../../core/services/route_navigation_service.dart';
import '../../domain/entities/staff_task_entity.dart';

/// Capa: Presentation (State)
class StaffHomeState {
  final List<StaffTaskEntity> tasks;
  final bool isLoading;
  final bool isStartingNavigation;
  final String? errorMessage;
  final ReportFilter selectedFilter;
  final String searchQuery;

  /// Tarea actualmente en atención con navegación activa en el mapa
  final StaffTaskEntity? activeNavigationTask;

  /// Ruta óptima calculada desde la ubicación actual del trabajador hasta el reporte
  final RouteInfoResult? activeRoute;

  /// Coordenadas GPS obtenidas del trabajador al iniciar la ruta
  final double? workerLatitude;
  final double? workerLongitude;

  const StaffHomeState({
    this.tasks = const [],
    this.isLoading = false,
    this.isStartingNavigation = false,
    this.errorMessage,
    this.selectedFilter = ReportFilter.all,
    this.searchQuery = '',
    this.activeNavigationTask,
    this.activeRoute,
    this.workerLatitude,
    this.workerLongitude,
  });

  int get pendingCount => tasks.where((t) => t.isPending).length;
  int get inProgressCount => tasks.where((t) => t.isInProgress).length;
  int get resolvedCount => tasks.where((t) => t.isResolved).length;

  /// Retorna la tarea actualmente en estado «En proceso» (si existe).
  /// Regla de negocio: solo se permite una tarea iniciada a la vez.
  StaffTaskEntity? get currentInProgressTask {
    if (activeNavigationTask != null && activeNavigationTask!.isInProgress) {
      return activeNavigationTask;
    }
    for (final t in tasks) {
      if (t.isInProgress) return t;
    }
    return null;
  }

  List<StaffTaskEntity> get filteredTasks {
    var list = tasks;
    switch (selectedFilter) {
      case ReportFilter.pending:
        list = list.where((t) => t.isPending).toList();
        break;
      case ReportFilter.inProgress:
        list = list.where((t) => t.isInProgress).toList();
        break;
      case ReportFilter.resolved:
        list = list.where((t) => t.isResolved).toList();
        break;
      case ReportFilter.all:
        break;
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((t) =>
        t.reportNumber.toLowerCase().contains(q) ||
        t.categoryName.toLowerCase().contains(q) ||
        t.address.toLowerCase().contains(q) ||
        t.description.toLowerCase().contains(q)
      ).toList();
    }

    return list;
  }

  StaffHomeState copyWith({
    List<StaffTaskEntity>? tasks,
    bool? isLoading,
    bool? isStartingNavigation,
    String? errorMessage,
    bool clearError = false,
    ReportFilter? selectedFilter,
    String? searchQuery,
    StaffTaskEntity? activeNavigationTask,
    RouteInfoResult? activeRoute,
    double? workerLatitude,
    double? workerLongitude,
    bool clearActiveNavigation = false,
  }) {
    return StaffHomeState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isStartingNavigation: isStartingNavigation ?? this.isStartingNavigation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      activeNavigationTask: clearActiveNavigation
          ? null
          : (activeNavigationTask ?? this.activeNavigationTask),
      activeRoute: clearActiveNavigation
          ? null
          : (activeRoute ?? this.activeRoute),
      workerLatitude: workerLatitude ?? this.workerLatitude,
      workerLongitude: workerLongitude ?? this.workerLongitude,
    );
  }
}
