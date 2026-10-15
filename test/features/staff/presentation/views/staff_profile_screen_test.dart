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
import 'package:ecoroute/features/staff/presentation/views/staff_profile_screen.dart';

class MockStaffAuthViewModel extends AuthViewModel {
  final UserEntity? testUser;
  bool logoutCalled = false;

  MockStaffAuthViewModel(this.testUser);

  @override
  AuthState build() {
    return AuthState(
      user: testUser,
      isInitialized: true,
    );
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = const AuthState(isInitialized: true, user: null);
  }
}

class MockStaffRepository implements StaffRepository {
  @override
  Future<Result<List<StaffTaskEntity>>> getAssignedTasks(String staffId) async {
    return const Success([]);
  }

  @override
  Future<Result<StaffTaskEntity>> getTaskById(String taskId) async {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  Future<Result<StaffTaskEntity>> completeTaskWithEvidence({
    required String taskId,
    required String staffId,
    required String staffName,
    required List<int> evidenceImageBytes,
    required String notes,
  }) async {
    throw UnimplementedError();
  }
}

final testStaffUser = UserEntity(
  id: 'staff-101',
  name: 'Carlos Cuadrilla',
  email: 'carlos.cuadrilla@ecoroute.com',
  role: UserRole.staff,
  createdAt: DateTime(2025, 1, 1),
);

void main() {
  testWidgets('Renderiza StaffProfileScreen con ficha de operario, asignación y métricas',
      (tester) async {
    final mockAuth = MockStaffAuthViewModel(testStaffUser);
    final mockRepo = MockStaffRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => mockAuth),
          staffRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: StaffProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Título de AppBar
    expect(find.text('Perfil Operativo'), findsOneWidget);

    // 2. Ficha de Identidad
    expect(find.text('Carlos Cuadrilla'), findsOneWidget);
    expect(find.text('carlos.cuadrilla@ecoroute.com'), findsOneWidget);
    expect(find.text('Cuadrilla de Campo'), findsOneWidget);
    expect(find.text('Legajo #OP-2048'), findsOneWidget);

    // 3. Control de Estado de Turno
    expect(find.text('Estado de Turno'), findsOneWidget);
    expect(find.text('En turno'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);

    // 4. Asignación Operativa
    expect(find.text('Asignación Operativa'), findsOneWidget);
    expect(find.text('Personal Asignado'), findsOneWidget);
    expect(find.text('Cuadrilla Zona Norte (Turno Diurno)'), findsOneWidget);
    expect(find.text('Unidad Vehicular'), findsOneWidget);
    expect(find.text('Camión Recolector #04 • Placa ECR-882'), findsOneWidget);
    expect(find.text('Zona de Cobertura'), findsOneWidget);

    // 5. Rendimiento en campo
    expect(find.text('Rendimiento en Campo'), findsOneWidget);
    expect(find.text('Resueltas Hoy'), findsOneWidget);
    expect(find.text('Por Atender'), findsOneWidget);
    expect(find.text('Tasa a Tiempo'), findsOneWidget);
    expect(find.text('Horas en Turno'), findsOneWidget);

    // 6. Botón de Cerrar Sesión Operativa
    expect(find.text('Cerrar Sesión Operativa'), findsOneWidget);

    // 7. Navegación inferior
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Tareas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('Permite cambiar el estado de turno abriendo el modal interactivo', (tester) async {
    final mockAuth = MockStaffAuthViewModel(testStaffUser);
    final mockRepo = MockStaffRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => mockAuth),
          staffRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: StaffProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap en botón 'Cambiar'
    final changeButton = find.text('Cambiar');
    expect(changeButton, findsOneWidget);
    await tester.tap(changeButton);
    await tester.pumpAndSettle();

    // Debe abrir el modal de estado de turno
    expect(find.text('Estado de turno operativo'), findsOneWidget);
    expect(find.text('Pausa para refrigerio o mantenimiento'), findsOneWidget);

    // Seleccionar la opción de descanso
    await tester.tap(find.text('Pausa para refrigerio o mantenimiento'));
    await tester.pumpAndSettle();

    // El estado en pantalla debe actualizarse a 'En descanso'
    expect(find.text('En descanso'), findsOneWidget);
  });

  testWidgets('Muestra diálogo de confirmación antes de cerrar sesión', (tester) async {
    final mockAuth = MockStaffAuthViewModel(testStaffUser);
    final mockRepo = MockStaffRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => mockAuth),
          staffRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: StaffProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll hasta el botón de cerrar sesión
    final logoutButton = find.text('Cerrar Sesión Operativa');
    await tester.ensureVisible(logoutButton);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    // Verifica que se muestre el diálogo de advertencia
    expect(find.text('¿Finalizar sesión?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);

    // Tocar cerrar sesión dentro del diálogo
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(mockAuth.logoutCalled, isTrue);
  });
}
