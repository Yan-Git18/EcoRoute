import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../../../core/enums/report_filter.dart';
import '../../data/datasources/staff_remote_datasource.dart';
import '../../data/datasources/staff_storage_datasource.dart';
import '../../data/repositories/staff_repository_impl.dart';
import '../../domain/entities/staff_task_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../../domain/usecases/complete_task_with_evidence_use_case.dart';
import '../../domain/usecases/get_assigned_tasks_use_case.dart';
import '../../domain/usecases/update_task_status_use_case.dart';
import 'staff_home_state.dart';

// --- Inyección de Dependencias con Riverpod ---

final staffRemoteDataSourceProvider = Provider<StaffRemoteDataSource>((ref) {
  return FirebaseStaffRemoteDataSourceImpl();
});

final staffStorageDataSourceProvider = Provider<StaffStorageDataSource>((ref) {
  return FirebaseStaffStorageDataSourceImpl();
});

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final remote = ref.watch(staffRemoteDataSourceProvider);
  final storage = ref.watch(staffStorageDataSourceProvider);
  return StaffRepositoryImpl(remoteDataSource: remote, storageDataSource: storage);
});

final getAssignedTasksUseCaseProvider = Provider<GetAssignedTasksUseCase>((ref) {
  final repository = ref.watch(staffRepositoryProvider);
  return GetAssignedTasksUseCase(repository);
});

final updateTaskStatusUseCaseProvider = Provider<UpdateTaskStatusUseCase>((ref) {
  final repository = ref.watch(staffRepositoryProvider);
  return UpdateTaskStatusUseCase(repository);
});

final completeTaskWithEvidenceUseCaseProvider = Provider<CompleteTaskWithEvidenceUseCase>((ref) {
  final repository = ref.watch(staffRepositoryProvider);
  return CompleteTaskWithEvidenceUseCase(repository);
});

final staffHomeViewModelProvider =
    NotifierProvider<StaffHomeViewModel, StaffHomeState>(StaffHomeViewModel.new);

// --- ViewModel (MVVM) ---

/// ViewModel para la gestión operativa del Personal de Campo.
///
/// Principio SRP: Gestiona exclusivamente el estado de la UI del panel de operaciones del personal.
///
/// Ubicación: `lib/features/staff/presentation/viewmodels/staff_home_viewmodel.dart`
/// Capa: Presentation (ViewModel)
class StaffHomeViewModel extends Notifier<StaffHomeState> {
  late final GetAssignedTasksUseCase _getTasksUseCase;
  late final UpdateTaskStatusUseCase _updateStatusUseCase;
  late final CompleteTaskWithEvidenceUseCase _completeTaskUseCase;
  late final MediaPickerService _mediaPickerService;

  @override
  StaffHomeState build() {
    _getTasksUseCase = ref.watch(getAssignedTasksUseCaseProvider);
    _updateStatusUseCase = ref.watch(updateTaskStatusUseCaseProvider);
    _completeTaskUseCase = ref.watch(completeTaskWithEvidenceUseCaseProvider);
    _mediaPickerService = ref.watch(mediaPickerServiceProvider);

    Future.microtask(() => loadTasks());

    return const StaffHomeState(isLoading: true);
  }

  /// Carga la lista de tareas de recolección asignadas al personal
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final authState = ref.read(authViewModelProvider);
    final staffId = authState.user?.id ?? 'staff_demo_user';

    final result = await _getTasksUseCase(staffId);

    result.fold(
      onSuccess: (tasks) {
        state = state.copyWith(tasks: tasks, isLoading: false);
      },
      onFailure: (failure) {
        state = state.copyWith(
          tasks: const [],
          isLoading: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  /// Iniciar la atención de una tarea (Cambia estado a 'inProgress')
  Future<bool> startTask(String taskId) async {
    final authState = ref.read(authViewModelProvider);
    final user = authState.user;

    final result = await _updateStatusUseCase(
      taskId: taskId,
      staffId: user?.id ?? 'staff_demo',
      staffName: user?.name ?? 'Personal de Campo',
      newStatus: ReportStatus.inProgress,
      notes: 'Cuadrilla de recolección en ruta hacia la ubicación.',
    );

    return result.fold(
      onSuccess: (updatedTask) {
        final currentTasks = List<StaffTaskEntity>.from(state.tasks);
        final index = currentTasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          currentTasks[index] = updatedTask;
        } else {
          currentTasks.insert(0, updatedTask);
        }
        state = state.copyWith(tasks: currentTasks);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
    );
  }

  /// Capturar o seleccionar foto de evidencia de limpieza y finalizar la tarea
  Future<MediaPickResult> pickEvidenceImageFromCamera() async {
    return await _mediaPickerService.pickImageFromCamera();
  }

  Future<MediaPickResult> pickEvidenceImageFromGallery() async {
    return await _mediaPickerService.pickImageFromGallery();
  }

  /// Completar y resolver una tarea de limpieza con foto y notas
  Future<bool> completeTask({
    required String taskId,
    required List<int> imageBytes,
    required String notes,
  }) async {
    final authState = ref.read(authViewModelProvider);
    final user = authState.user;

    final result = await _completeTaskUseCase(
      taskId: taskId,
      staffId: user?.id ?? 'staff_demo',
      staffName: user?.name ?? 'Personal de Campo',
      evidenceImageBytes: imageBytes,
      notes: notes,
    );

    return result.fold(
      onSuccess: (resolvedTask) {
        final currentTasks = List<StaffTaskEntity>.from(state.tasks);
        final index = currentTasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          currentTasks[index] = resolvedTask;
        } else {
          currentTasks.insert(0, resolvedTask);
        }
        state = state.copyWith(tasks: currentTasks);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
    );
  }

  void setFilter(ReportFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<void> refresh() async {
    await loadTasks();
  }
}
