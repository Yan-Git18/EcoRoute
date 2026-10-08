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
import 'package:ecoroute/features/staff/presentation/views/staff_home_screen.dart';

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

final testStaffUser = UserEntity(
  id: 'staff-1',
  name: 'Mario Limpieza',
  email: 'mario@ecoroute.com',
  role: UserRole.staff,
  createdAt: DateTime(2025, 1, 1),
);

void main() {
  testWidgets('Renderiza StaffHomeScreen con diseño de Operaciones coincidente con el mockup',
      (tester) async {
    final mockRepo = MockStaffRepository();
    mockRepo.tasks = []; // Probará el fallback que coincide exactamente con el mockup

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockStaffAuthViewModel(testStaffUser)),
          staffRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: StaffHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Cabecera y AppBar
    expect(find.text('Panel de Operaciones'), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // 2. Tarjeta del personal y estado de turno
    expect(find.text('Mario Limpieza'), findsOneWidget);
    expect(find.text('Cuadrilla Zona Norte'), findsOneWidget);
    expect(find.text('En turno'), findsOneWidget);
    expect(find.text('Cambiar estado'), findsOneWidget);

    // 3. Sección "Mis tareas" con contadores
    expect(find.text('Mis tareas'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('En proceso'), findsOneWidget);
    expect(find.text('Resueltas'), findsOneWidget);

    // 4. Sección "Siguiente tarea"
    expect(find.text('Siguiente tarea'), findsOneWidget);
    expect(find.text('Contenedor lleno'), findsOneWidget);
    expect(find.text('Av. Los Próceres 452'), findsOneWidget);
    expect(find.text('Alta prioridad'), findsWidgets);
    expect(find.text('Atender'), findsOneWidget);

    // 5. Sección "Otras tareas"
    expect(find.text('Otras tareas'), findsOneWidget);
    expect(find.text('Residuos en vía pública'), findsOneWidget);
    expect(find.text('Jr. Amazonas 120'), findsOneWidget);
    expect(find.text('Media prioridad'), findsWidgets);
    expect(find.text('Punto de recolección'), findsOneWidget);
    expect(find.text('Parque Central'), findsOneWidget);
    expect(find.text('Baja prioridad'), findsOneWidget);

    // 6. Barra de navegación inferior
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Tareas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });
}
