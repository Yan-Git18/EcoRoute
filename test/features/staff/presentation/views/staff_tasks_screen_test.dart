import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/services/location_service.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/staff/domain/entities/staff_task_entity.dart';
import 'package:ecoroute/features/staff/domain/repositories/staff_repository.dart';
import 'package:ecoroute/features/staff/presentation/viewmodels/staff_home_viewmodel.dart';
import 'package:ecoroute/features/staff/presentation/views/staff_tasks_screen.dart';

class MockTasksLocationService implements LocationService {
  int getCurrentPositionCalls = 0;

  @override
  Future<LocationDataResult> getCurrentPosition() async {
    getCurrentPositionCalls++;
    return const LocationDataResult(
      latitude: -7.1580,
      longitude: -78.5180,
      address: 'Plaza de Armas, Cajamarca',
    );
  }

  @override
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    return 'Plaza de Armas, Cajamarca';
  }

  @override
  Future<LocationDataResult?> getCoordinatesFromAddress(String address) async {
    return null;
  }
}

class MockStaffAuthViewModel extends AuthViewModel {
  final UserEntity? testUser;
  MockStaffAuthViewModel(this.testUser);

  @override
  AuthState build() {
    return AuthState(
      user: testUser,
      isInitialized: true,
    );
  }
}

class MockStaffRepository implements StaffRepository {
  List<StaffTaskEntity> tasks = [];
  int updateTaskStatusCalls = 0;

  @override
  Future<Result<List<StaffTaskEntity>>> getAssignedTasks(String staffId) async {
    return Success(tasks);
  }

  @override
  Future<Result<StaffTaskEntity>> getTaskById(String taskId) async {
    final match = tasks.firstWhere((t) => t.id == taskId);
    return Success(match);
  }

  @override
  Future<Result<StaffTaskEntity>> updateTaskStatus({
    required String taskId,
    required String staffId,
    required String staffName,
    required ReportStatus newStatus,
    String? notes,
    String? evidenceImageUrl,
  }) async {
    updateTaskStatusCalls++;
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final updated = tasks[idx].copyWith(status: newStatus);
      tasks[idx] = updated;
      return Success(updated);
    }
    final match = tasks.firstWhere((t) => t.id == taskId);
    return Success(match.copyWith(status: newStatus));
  }

  @override
  Future<Result<StaffTaskEntity>> completeTaskWithEvidence({
    required String taskId,
    required String staffId,
    required String staffName,
    List<int>? evidenceImageBytes,
    List<List<int>>? multipleEvidenceBytes,
    required String notes,
    String? localImagePath,
    List<String>? localImagePaths,
  }) async {
    final match = tasks.firstWhere((t) => t.id == taskId);
    final updated = match.copyWith(
      status: ReportStatus.resolved,
      resolutionNotes: notes,
    );
    return Success(updated);
  }
}

final testStaff = UserEntity(
  id: 'staff-test-1',
  name: 'Carlos Cuadrilla',
  email: 'carlos@ecoroute.com',
  role: UserRole.staff,
  createdAt: DateTime(2025, 1, 1),
);

void main() {
  testWidgets('Renderiza StaffTasksScreen con buscador, chips de filtro y lista de tareas',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRepo = MockStaffRepository();
    mockRepo.tasks = []; // Utiliza el fallback de demostración

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockStaffAuthViewModel(testStaff)),
          staffRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: StaffTasksScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Título y AppBar
    expect(find.text('Gestión de Tareas'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    // 2. Buscador de texto
    expect(find.text('Buscar por folio (#0102), dirección o residuo...'), findsOneWidget);

    // 3. Chips de filtro
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('En proceso'), findsOneWidget);
    expect(find.text('Resueltas'), findsOneWidget);

    // 4. Barra de ordenamiento (por defecto: Más recientes)
    expect(find.text('Ordenar por: Más recientes'), findsOneWidget);

    // 5. Tareas mostradas en pantalla
    expect(find.text('#0102'), findsOneWidget);
    expect(find.text('Contenedor lleno'), findsOneWidget);
    expect(find.text('#0103'), findsOneWidget);

    // 6. Cambiar ordenamiento manualmente a Prioridad
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prioridad (Alta primero)'));
    await tester.pumpAndSettle();
    expect(find.text('Ordenar por: Prioridad (Alta primero)'), findsOneWidget);

    // 7. Barra de navegación inferior
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Tareas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('Filtra tareas al escribir en el buscador de StaffTasksScreen',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRepo = MockStaffRepository();
    mockRepo.tasks = [];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockStaffAuthViewModel(testStaff)),
          staffRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: StaffTasksScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Escribimos '#0102' en el buscador
    await tester.enterText(
      find.byType(TextField),
      '#0102',
    );
    await tester.pumpAndSettle();

    // Solo debe aparecer la tarea coincidente ('Contenedor lleno') y no la otra ('Jr. Amazonas 120')
    expect(find.text('Contenedor lleno'), findsOneWidget);
    expect(find.text('Av. Los Próceres 452'), findsOneWidget);
    expect(find.text('Jr. Amazonas 120'), findsNothing);
  });

  testWidgets(
      'Flujo al presionar Iniciar: muestra confirmación, cancelar no altera estado y Sí iniciar actualiza a en progreso, obtiene geolocalización y redirige al mapa con la ruta óptima',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRepo = MockStaffRepository();
    mockRepo.tasks = [
      StaffTaskEntity(
        id: 'task-nav-1',
        reportNumber: '#0102',
        citizenId: 'cit-1',
        citizenName: 'María López',
        categoryName: 'Contenedor lleno',
        categoryIcon: 'delete',
        description: 'Contenedor desbordado frente al mercado.',
        address: 'Av. Los Próceres 452, Cajamarca',
        latitude: -7.1638,
        longitude: -78.5002,
        status: ReportStatus.pending,
        priority: ReportPriority.high,
        reportImageUrls: const [],
        assignedAt: DateTime(2026, 3, 22, 8, 0),
      ),
      StaffTaskEntity(
        id: 'task-nav-2',
        reportNumber: '#0103',
        citizenId: 'cit-2',
        citizenName: 'Juan Pérez',
        categoryName: 'Residuos en vía pública',
        categoryIcon: 'cleaning_services',
        description: 'Bolsas acumuladas en esquina.',
        address: 'Jr. Amazonas 120, Cajamarca',
        latitude: -7.1565,
        longitude: -78.5160,
        status: ReportStatus.pending,
        priority: ReportPriority.medium,
        reportImageUrls: const [],
        assignedAt: DateTime(2026, 3, 22, 7, 0),
      ),
    ];
    final mockLoc = MockTasksLocationService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockStaffAuthViewModel(testStaff)),
          staffRepositoryProvider.overrideWithValue(mockRepo),
          locationServiceProvider.overrideWithValue(mockLoc),
        ],
        child: const MaterialApp(
          home: StaffTasksScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verificar que las tareas están en estado Pendiente con botón "Iniciar"
    expect(find.text('Iniciar'), findsNWidgets(2));
    expect(mockRepo.updateTaskStatusCalls, 0);
    expect(mockLoc.getCurrentPositionCalls, 0);

    // 2. Presionar "Iniciar" en la primera tarea -> debe abrir el diálogo de confirmación
    await tester.tap(find.text('Iniciar').first);
    await tester.pumpAndSettle();

    expect(find.text('Iniciar atención de tarea'), findsOneWidget);
    expect(
      find.text('¿Está seguro de que desea iniciar esta tarea?'),
      findsOneWidget,
    );
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Sí, iniciar'), findsOneWidget);

    // 3. Presionar "Cancelar" -> no debe cambiar estado, ni llamar GPS, ni navegar
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar atención de tarea'), findsNothing);
    expect(mockRepo.updateTaskStatusCalls, 0);
    expect(mockLoc.getCurrentPositionCalls, 0);
    expect(find.text('Gestión de Tareas'), findsOneWidget);
    expect(find.text('Iniciar'), findsNWidgets(2));

    // 4. Presionar "Iniciar" nuevamente y confirmar con "Sí, iniciar"
    await tester.tap(find.text('Iniciar').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sí, iniciar'));
    await tester.pumpAndSettle();

    // 5. Verificar que actualizó el estado, obtuvo ubicación actual y redirigió al Mapa
    expect(mockRepo.updateTaskStatusCalls, 1);
    expect(mockRepo.tasks.first.status, ReportStatus.inProgress);
    expect(mockLoc.getCurrentPositionCalls, greaterThanOrEqualTo(1));

    // Debe haberse redirigido a StaffRouteMapScreen mostrando solo la ruta hacia #0102
    expect(find.text('Ruta hacia #0102'), findsOneWidget);
    expect(find.text('Ruta óptima activa'), findsOneWidget);
    expect(find.textContaining('En ruta a #0102'), findsOneWidget);
    expect(find.textContaining('Distancia:'), findsWidgets);
    expect(find.textContaining('Llegada'), findsWidgets);

    // 6. Volver a la lista de tareas e intentar iniciar la segunda tarea (#0103)
    // mientras #0102 sigue en curso -> debe bloquearse con alerta de tarea activa
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Gestión de Tareas'), findsOneWidget);
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();

    expect(find.text('Ya tienes una tarea en curso'), findsOneWidget);
    expect(mockRepo.updateTaskStatusCalls, 1); // No permitió iniciar una segunda tarea
  });
}
