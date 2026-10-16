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
  name: 'Carlos Mendoza',
  email: 'carlos.mendoza@ecoroute.com',
  role: UserRole.staff,
  createdAt: DateTime(2025, 1, 1),
);

void main() {
  testWidgets('Renderiza StaffProfileScreen con diseno de tarjeta y opciones operativas',
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

    // 1. Título de AppBar centrado 'Mi perfil'
    expect(find.text('Mi perfil'), findsOneWidget);

    // 2. Ficha de Identidad del Personal
    expect(find.text('Carlos Mendoza'), findsOneWidget);
    expect(find.text('Equipo de limpieza #03'), findsOneWidget);
    expect(find.byIcon(Icons.engineering_rounded), findsOneWidget);

    // 3. Opciones principales en la tarjeta
    expect(find.text('Mis estadísticas'), findsOneWidget);
    expect(find.text('Historial de tareas'), findsOneWidget);
    expect(find.text('Configuración'), findsOneWidget);
    expect(find.text('Ayuda y soporte'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);

    // 4. Barra de navegación inferior
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Tareas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('Configuracion abre modal con Mis datos, Cambiar contrasena y Notificaciones',
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

    // Tocar 'Configuración'
    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();

    // Verificar que el modal de Configuración se abre con las 3 opciones requeridas
    expect(find.text('Mis datos'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.text('Notificaciones'), findsOneWidget);

    // Verificar que NO incluye 'Acerca de EcoRoute' ni 'Cerrar sesión' dentro del modal
    expect(find.text('Acerca de EcoRoute'), findsNothing);

    // Probar abrir 'Mis datos'
    await tester.tap(find.text('Mis datos'));
    await tester.pumpAndSettle();

    expect(find.text('Mis datos personales'), findsOneWidget);
    expect(find.text('carlos.mendoza@ecoroute.com'), findsOneWidget);
    expect(find.text('Personal de Limpieza'), findsOneWidget);
  });

  testWidgets('Mis estadisticas abre modal con rendimiento y estado de turno',
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

    // Tocar 'Mis estadísticas'
    await tester.tap(find.text('Mis estadísticas'));
    await tester.pumpAndSettle();

    // Debe mostrar métricas y estado de turno
    expect(find.text('Estado de Turno'), findsOneWidget);
    expect(find.text('En turno'), findsOneWidget);
    expect(find.text('Resueltas Hoy'), findsOneWidget);
    expect(find.text('Por Atender'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);

    // Probar interactuar con 'Cambiar' turno
    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();

    expect(find.text('Estado de turno operativo'), findsOneWidget);
  });

  testWidgets('Historial de tareas abre modal con paradas recientes', (tester) async {
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

    await tester.tap(find.text('Historial de tareas'));
    await tester.pumpAndSettle();

    expect(find.text('Ver todas las tareas en el panel'), findsOneWidget);
    expect(find.textContaining('Contenedor lleno'), findsOneWidget);
  });

  testWidgets('Muestra dialogo de confirmacion y permite cerrar sesion', (tester) async {
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

    // Tocar 'Cerrar sesión'
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    // Verifica que se muestre el diálogo de advertencia
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    // Tocar confirmar en el diálogo
    final confirmButtons = find.widgetWithText(ElevatedButton, 'Cerrar sesión');
    expect(confirmButtons, findsOneWidget);
    await tester.tap(confirmButtons);
    await tester.pumpAndSettle();

    expect(mockAuth.logoutCalled, isTrue);
  });
}
