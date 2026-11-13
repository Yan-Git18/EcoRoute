import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/route_navigation_service.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../../../core/enums/report_filter.dart';
import '../../data/datasources/staff_remote_datasource.dart';
import '../../data/datasources/staff_storage_datasource.dart';
import '../../data/fixtures/staff_tasks_fixtures.dart';
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
  late final LocationService _locationService;
  late final RouteNavigationService _routeNavigationService;

  @override
  StaffHomeState build() {
    _getTasksUseCase = ref.watch(getAssignedTasksUseCaseProvider);
    _updateStatusUseCase = ref.watch(updateTaskStatusUseCaseProvider);
    _completeTaskUseCase = ref.watch(completeTaskWithEvidenceUseCaseProvider);
    _mediaPickerService = ref.watch(mediaPickerServiceProvider);
    _locationService = ref.watch(locationServiceProvider);
    _routeNavigationService = ref.watch(routeNavigationServiceProvider);

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
        StaffTaskEntity? inProgressTask;
        for (final t in tasks) {
          if (t.isInProgress) {
            inProgressTask = t;
            break;
          }
        }
        state = state.copyWith(
          tasks: tasks,
          isLoading: false,
          activeNavigationTask: inProgressTask ?? state.activeNavigationTask,
        );
        if (inProgressTask != null && state.activeRoute == null) {
          Future.microtask(() => focusTaskRouteOnMap(inProgressTask!));
        }
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

  /// Iniciar la atención de una tarea (Cambia estado a 'inProgress').
  /// Respeta la regla de negocio de solo 1 tarea en curso a la vez.
  Future<bool> startTask(String taskId) async {
    final existingActive = state.currentInProgressTask;
    if (existingActive != null && existingActive.id != taskId) {
      state = state.copyWith(
        errorMessage:
            'Ya tienes la tarea ${existingActive.reportNumber} en curso. Debes resolverla antes de iniciar otra.',
      );
      return false;
    }

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

  /// Flujo completo al confirmar «Sí, iniciar» sobre una tarea pendiente:
  /// 1. Valida que no exista otra tarea en progreso (solo 1 tarea activa a la vez).
  /// 2. Actualiza el estado de la tarea de «Pendiente» a «En progreso» (ReportStatus.inProgress).
  /// 3. Obtiene la ubicación GPS actual real del trabajador mediante [LocationService].
  /// 4. Obtiene las coordenadas reales del reporte seleccionado.
  /// 5. Calcula la ruta óptima por calles desde la ubicación actual hasta el reporte.
  /// 6. Registra la tarea y la ruta activa en el estado para su visualización limpia en el Mapa.
  Future<bool> startTaskWithNavigation(StaffTaskEntity task) async {
    final existingActive = state.currentInProgressTask;
    if (existingActive != null && existingActive.id != task.id) {
      state = state.copyWith(
        isStartingNavigation: false,
        errorMessage:
            'Ya tienes la tarea ${existingActive.reportNumber} en curso. Debes resolverla antes de iniciar otra.',
      );
      return false;
    }

    state = state.copyWith(isStartingNavigation: true, clearError: true);

    final authState = ref.read(authViewModelProvider);
    final user = authState.user;

    // 1. Actualizar el estado de la tarea de Pendiente a En progreso
    StaffTaskEntity? updatedTask;
    bool statusUpdated = false;

    if (state.tasks.isEmpty && task.id.startsWith('task-demo-')) {
      updatedTask = task.copyWith(status: ReportStatus.inProgress);
      statusUpdated = true;
    } else {
      final statusResult = await _updateStatusUseCase(
        taskId: task.id,
        staffId: user?.id ?? 'staff_demo',
        staffName: user?.name ?? 'Personal de Campo',
        newStatus: ReportStatus.inProgress,
        notes: 'Cuadrilla de recolección en ruta hacia la ubicación.',
      );

      statusUpdated = statusResult.fold(
        onSuccess: (t) {
          updatedTask = t;
          return true;
        },
        onFailure: (failure) {
          if (task.id.startsWith('task-demo-')) {
            updatedTask = task.copyWith(status: ReportStatus.inProgress);
            return true;
          }
          state = state.copyWith(
            isStartingNavigation: false,
            errorMessage: failure.message,
          );
          return false;
        },
      );
    }

    if (!statusUpdated || updatedTask == null) {
      return false;
    }

    final baseList = state.tasks.isNotEmpty
        ? List<StaffTaskEntity>.from(state.tasks)
        : List<StaffTaskEntity>.from(StaffTasksFixtures.defaultDemoTasks);
    final index = baseList.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      baseList[index] = updatedTask!;
    } else {
      baseList.insert(0, updatedTask!);
    }

    // 2. Obtener la ubicación actual del trabajador mediante el servicio de geolocalización
    final locResult = await _locationService.getCurrentPosition();
    final workerLat = locResult.latitude;
    final workerLng = locResult.longitude;

    // 3. Obtener las coordenadas reales del reporte seleccionado
    final destLat = updatedTask!.latitude;
    final destLng = updatedTask!.longitude;

    // 4. Calcular la ruta óptima entre la ubicación del trabajador y el reporte
    final routeInfo = await _routeNavigationService.calculateOptimalRoute(
      originLat: workerLat,
      originLng: workerLng,
      destLat: destLat,
      destLng: destLng,
    );

    // 5. Actualizar el estado con la tarea en progreso y la ruta calculada
    state = state.copyWith(
      tasks: baseList,
      isStartingNavigation: false,
      activeNavigationTask: updatedTask,
      activeRoute: routeInfo,
      workerLatitude: workerLat,
      workerLongitude: workerLng,
    );

    return true;
  }

  /// Calcula y muestra en el mapa la ruta óptima hacia una tarea que ya se encuentra «En proceso».
  /// No traza rutas para tareas pendientes no iniciadas.
  Future<void> focusTaskRouteOnMap(StaffTaskEntity task) async {
    if (!task.isInProgress) return;

    final locResult = await _locationService.getCurrentPosition();
    final workerLat = locResult.latitude;
    final workerLng = locResult.longitude;

    final routeInfo = await _routeNavigationService.calculateOptimalRoute(
      originLat: workerLat,
      originLng: workerLng,
      destLat: task.latitude,
      destLng: task.longitude,
    );

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

  /// Capturar o seleccionar foto de evidencia de limpieza y finalizar la tarea
  Future<MediaPickResult> pickEvidenceImageFromCamera() async {
    return await _mediaPickerService.pickImageFromCamera();
  }

  Future<MediaPickResult> pickEvidenceImageFromGallery() async {
    return await _mediaPickerService.pickImageFromGallery();
  }

  /// Completar y resolver una tarea de limpieza con foto(s) y notas
  Future<bool> completeTask({
    required String taskId,
    List<int>? imageBytes,
    List<List<int>>? multipleImageBytes,
    required String notes,
    String? localImagePath,
    List<String>? localImagePaths,
  }) async {
    final authState = ref.read(authViewModelProvider);
    final user = authState.user;

    final result = await _completeTaskUseCase(
      taskId: taskId,
      staffId: user?.id ?? 'staff_demo',
      staffName: user?.name ?? 'Personal de Campo',
      evidenceImageBytes: imageBytes,
      multipleEvidenceBytes: multipleImageBytes,
      notes: notes,
      localImagePath: localImagePath,
      localImagePaths: localImagePaths,
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
        final isCompletingActiveNav = state.activeNavigationTask?.id == taskId;
        state = state.copyWith(
          tasks: currentTasks,
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
