import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/route_navigation_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../../../core/enums/report_filter.dart';
import '../../data/datasources/staff_remote_datasource.dart';
import '../../data/repositories/staff_repository_impl.dart';
import '../../domain/entities/staff_task_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../../domain/usecases/complete_task_with_evidence_use_case.dart';
import '../../domain/usecases/get_assigned_tasks_use_case.dart';
import '../../domain/usecases/update_task_status_use_case.dart';
import 'staff_home_state.dart';
import 'staff_operations_providers.dart';

// --- Inyección de Dependencias con Riverpod ---

final staffRemoteDataSourceProvider = Provider<StaffRemoteDataSource>((ref) {
  return FirebaseStaffRemoteDataSourceImpl();
});

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final remote = ref.watch(staffRemoteDataSourceProvider);
  return StaffRepositoryImpl(remoteDataSource: remote);
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
  (String, String?)? _session;
  int _sessionVersion = 0;
  int _loadVersion = 0;

  @override
  StaffHomeState build() {
    final session = ref.watch(
      authViewModelProvider.select((auth) => _sessionOf(auth.user)),
    );
    _session = session;
    final version = ++_sessionVersion;
    if (session != null) {
      ref.listen(staffTeamIdProvider, (previous, next) {
        if (next case AsyncData(value: final newTeam)) {
          final oldTeam = switch (previous) {
            AsyncData(:final value) => value,
            _ => session.$2,
          };
          if (oldTeam != newTeam) loadTasks();
        }
      });
      ref.listen(staffTeamTaskChangesProvider, (_, next) {
        if (next is AsyncData<int>) loadTasks(showLoading: false);
      });
      Future.microtask(() async {
        if (_isCurrentSession(version)) await loadTasks();
      });
    }
    return StaffHomeState(isLoading: session != null);
  }

  UserEntity? get _staffUser {
    final user = ref.read(authViewModelProvider).user;
    return user != null && user.isStaff && user.isActive ? user : null;
  }

  static (String, String?)? _sessionOf(UserEntity? user) =>
      user != null && user.isStaff && user.isActive ? (user.id, user.teamId) : null;

  bool _isCurrentSession(int version) =>
      ref.mounted &&
      version == _sessionVersion &&
      _sessionOf(ref.read(authViewModelProvider).user) == _session;

  /// Carga la lista de tareas de recolección asignadas al personal
  Future<void> loadTasks({bool showLoading = true}) async {
    final user = _staffUser;
    if (user == null) return;
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearLoadError: true);
    }

    final session = _sessionVersion;
    final load = ++_loadVersion;
    final result = await ref.read(getAssignedTasksUseCaseProvider)(user.id);
    if (!_isCurrentSession(session) || load != _loadVersion) return;

    result.fold(
      onSuccess: (tasks) {
        final inProgress = tasks.where((task) => task.isInProgress);
        final previousTaskId = state.activeNavigationTask?.id;
        final activeTask = inProgress
                .where((task) => task.id == previousTaskId)
                .firstOrNull ??
            inProgress.firstOrNull;
        final keepRoute = activeTask != null && activeTask.id == previousTaskId;
        state = state.copyWith(
          tasks: tasks,
          isLoading: false,
          clearLoadError: true,
          clearActiveNavigation: !keepRoute,
          activeNavigationTask: activeTask,
        );
        if (activeTask != null && state.activeRoute == null) {
          focusTaskRouteOnMap(activeTask);
        }
      },
      onFailure: (failure) {
        state = state.copyWith(
          tasks: const [],
          isLoading: false,
          clearActiveNavigation: true,
          loadErrorMessage: failure.message,
        );
      },
    );
  }

  /// Iniciar la atención de una tarea (Cambia estado a 'inProgress').
  /// Respeta la regla de negocio de solo 1 tarea en curso a la vez.
  Future<bool> startTask(String taskId) async {
    final user = _staffUser;
    if (user == null || !_canManageTask(taskId)) return false;
    final existingActive = state.currentInProgressTask;
    if (existingActive != null && existingActive.id != taskId) {
      state = state.copyWith(
        errorMessage:
            'Ya tienes la tarea ${existingActive.reportNumber} en curso. Debes resolverla antes de iniciar otra.',
      );
      return false;
    }

    final session = _sessionVersion;
    final result = await ref.read(updateTaskStatusUseCaseProvider)(
      taskId: taskId,
      staffId: user.id,
      staffName: user.name,
      newStatus: ReportStatus.inProgress,
      notes: 'Cuadrilla de recolección en ruta hacia la ubicación.',
    );
    if (!_isCurrentSession(session)) return false;

    return result.fold(
      onSuccess: (updatedTask) {
        final currentTasks = List<StaffTaskEntity>.from(state.tasks);
        final index = currentTasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          currentTasks[index] = updatedTask;
        } else {
          currentTasks.insert(0, updatedTask);
        }
        _loadVersion++;
        state = state.copyWith(tasks: currentTasks, isLoading: false);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        if (failure.code == 'permission-denied' || failure.code == 'active-task-exists') {
          loadTasks();
        }
        return false;
      },
    );
  }

  bool _canManageTask(String taskId) {
    final task = state.tasks.where((task) => task.id == taskId).firstOrNull;
    if (ref.read(staffCanManageTaskProvider(task?.teamId))) return true;
    state = state.copyWith(
      errorMessage: 'Solo el líder del equipo puede actualizar esta tarea.',
    );
    return false;
  }

  /// Flujo completo al confirmar «Sí, iniciar» sobre una tarea pendiente:
  /// 1. Valida que no exista otra tarea en progreso (solo 1 tarea activa a la vez).
  /// 2. Actualiza el estado de la tarea de «Pendiente» a «En progreso» (ReportStatus.inProgress).
  /// 3. Obtiene la ubicación GPS actual real del trabajador mediante [LocationService].
  /// 4. Obtiene las coordenadas reales del reporte seleccionado.
  /// 5. Calcula la ruta óptima por calles desde la ubicación actual hasta el reporte.
  /// 6. Registra la tarea y la ruta activa en el estado para su visualización limpia en el Mapa.
  Future<bool> startTaskWithNavigation(StaffTaskEntity task) async {
    if (state.isStartingNavigation) return false;
    state = state.copyWith(isStartingNavigation: true, clearError: true);
    final session = _sessionVersion;

    try {
      if (!await startTask(task.id) || !_isCurrentSession(session)) return false;
      final updated = state.tasks.where((item) => item.id == task.id).firstOrNull;
      if (updated != null) await focusTaskRouteOnMap(updated);
      return _isCurrentSession(session);
    } finally {
      if (_isCurrentSession(session)) {
        state = state.copyWith(isStartingNavigation: false);
      }
    }
  }

  /// Calcula y muestra en el mapa la ruta óptima hacia una tarea que ya se encuentra «En proceso».
  /// No traza rutas para tareas pendientes no iniciadas.
  Future<void> focusTaskRouteOnMap(
    StaffTaskEntity task, {
    LocationDataResult? position,
  }) async {
    if (!task.isInProgress) return;
    final session = _sessionVersion;
    final location = ref.read(locationServiceProvider);
    final routing = ref.read(routeNavigationServiceProvider);

    final locResult = position ?? await location.getCurrentPosition();
    if (!_isCurrentSession(session)) return;
    final hasPosition = locResult.errorMessage == null && !locResult.isPermissionDenied;
    if (!hasPosition || !task.hasReportLocation) {
      if (!state.tasks.any((item) => item.id == task.id && item.isInProgress)) return;
      state = state.copyWith(
        activeNavigationTask: task,
        clearActiveNavigation: true,
        clearWorkerPosition: !hasPosition,
        workerLatitude: hasPosition ? locResult.latitude : null,
        workerLongitude: hasPosition ? locResult.longitude : null,
      );
      return;
    }
    final workerLat = locResult.latitude;
    final workerLng = locResult.longitude;

    final routeInfo = await routing.calculateOptimalRoute(
      originLat: workerLat,
      originLng: workerLng,
      destLat: task.latitude,
      destLng: task.longitude,
    );
    if (!_isCurrentSession(session) ||
        !state.tasks.any((item) => item.id == task.id && item.isInProgress)) {
      return;
    }

    state = state.copyWith(
      activeNavigationTask: task,
      activeRoute: routeInfo,
      workerLatitude: workerLat,
      workerLongitude: workerLng,
    );
  }

  /// Limpia la navegación individual activa para volver a la vista de circuito general.
  void clearActiveNavigation() {
    state = state.copyWith(clearActiveNavigation: true);
  }

  /// Captura una foto de evidencia de limpieza.
  Future<MediaPickResult> pickEvidenceImageFromCamera() async {
    return ref.read(mediaPickerServiceProvider).pickImageFromCamera();
  }

  /// Completar y resolver una tarea de limpieza con foto(s) y notas
  Future<bool> completeTask({
    required String taskId,
    List<int>? imageBytes,
    List<List<int>>? multipleImageBytes,
    required String notes,
  }) async {
    final user = _staffUser;
    if (user == null || !_canManageTask(taskId)) return false;

    final session = _sessionVersion;
    final result = await ref.read(completeTaskWithEvidenceUseCaseProvider)(
      taskId: taskId,
      staffId: user.id,
      staffName: user.name,
      evidenceImageBytes: imageBytes,
      multipleEvidenceBytes: multipleImageBytes,
      notes: notes,
    );
    if (!_isCurrentSession(session)) return false;

    return result.fold(
      onSuccess: (resolvedTask) {
        final currentTasks = List<StaffTaskEntity>.from(state.tasks);
        final index = currentTasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          currentTasks[index] = resolvedTask;
        } else {
          currentTasks.insert(0, resolvedTask);
        }
        final isCompletingActiveNav = state.activeNavigationTask?.id == taskId;
        _loadVersion++;
        state = state.copyWith(
          tasks: currentTasks,
          isLoading: false,
          clearActiveNavigation: isCompletingActiveNav,
        );
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

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refresh() async {
    await loadTasks();
  }
}
