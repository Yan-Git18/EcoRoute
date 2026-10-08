import '../../../../core/enums/report_filter.dart';
import '../../domain/entities/staff_task_entity.dart';

/// Capa: Presentation (State)
class StaffHomeState {
  final List<StaffTaskEntity> tasks;
  final bool isLoading;
  final String? errorMessage;
  final ReportFilter selectedFilter;

  const StaffHomeState({
    this.tasks = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedFilter = ReportFilter.all,
  });

  int get pendingCount => tasks.where((t) => t.isPending).length;
  int get inProgressCount => tasks.where((t) => t.isInProgress).length;
  int get resolvedCount => tasks.where((t) => t.isResolved).length;

  List<StaffTaskEntity> get filteredTasks {
    switch (selectedFilter) {
      case ReportFilter.pending:
        return tasks.where((t) => t.isPending).toList();
      case ReportFilter.inProgress:
        return tasks.where((t) => t.isInProgress).toList();
      case ReportFilter.resolved:
        return tasks.where((t) => t.isResolved).toList();
      case ReportFilter.all:
        return tasks;
    }
  }

  StaffHomeState copyWith({
    List<StaffTaskEntity>? tasks,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    ReportFilter? selectedFilter,
  }) {
    return StaffHomeState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}
