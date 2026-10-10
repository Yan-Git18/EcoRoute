import '../../../../core/enums/report_filter.dart';
import '../../domain/entities/staff_task_entity.dart';

/// Capa: Presentation (State)
class StaffHomeState {
  final List<StaffTaskEntity> tasks;
  final bool isLoading;
  final String? errorMessage;
  final ReportFilter selectedFilter;

  final String searchQuery;

  const StaffHomeState({
    this.tasks = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedFilter = ReportFilter.all,
    this.searchQuery = '',
  });

  int get pendingCount => tasks.where((t) => t.isPending).length;
  int get inProgressCount => tasks.where((t) => t.isInProgress).length;
  int get resolvedCount => tasks.where((t) => t.isResolved).length;

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
    String? errorMessage,
    bool clearError = false,
    ReportFilter? selectedFilter,
    String? searchQuery,
  }) {
    return StaffHomeState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
