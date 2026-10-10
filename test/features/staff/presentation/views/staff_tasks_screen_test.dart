import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/staff/domain/entities/staff_task_entity.dart';
import 'package:ecoroute/features/staff/domain/repositories/staff_repository.dart';
import 'package:ecoroute/features/staff/presentation/viewmodels/staff_home_viewmodel.dart';
import 'package:ecoroute/features/staff/presentation/views/staff_tasks_screen.dart';

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
    final match = tasks.firstWhere((t) => t.id == taskId);
    final updated = match.copyWith(status: newStatus);
    return Success(updated);
  }

  @override
  Future<Result<StaffTaskEntity>> completeTaskWithEvidence({
    required String taskId,
    required String staffId,
    required String staffName,
    required List<int> evidenceImageBytes,
    required String notes,
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

    // 4. Barra de ordenamiento
    expect(find.textContaining('Ordenar por:'), findsOneWidget);

    // 5. Tareas mostradas en pantalla
    expect(find.text('#0102'), findsOneWidget);
    expect(find.text('Contenedor lleno'), findsOneWidget);
    expect(find.text('#0103'), findsOneWidget);

    // 6. Barra de navegación inferior
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
}
