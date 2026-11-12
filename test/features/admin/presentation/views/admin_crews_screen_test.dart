import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/admin/domain/entities/municipal_crew_entity.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_viewmodel.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_crews_screen.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_crew_card.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_crew_create_modal.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_crew_edit_modal.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';

class MockAdminAuthViewModel extends AuthViewModel {
  final UserEntity? testUser;
  MockAdminAuthViewModel(this.testUser);

  @override
  AuthState build() {
    return AuthState(
      user: testUser,
      isInitialized: true,
    );
  }
}

class MockAdminCrewsRepository implements AdminRepository {
  List<ReportEntity> reports = [];
  List<MunicipalCrewEntity> crews = [];

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async => Success(reports);

  @override
  Future<Result<List<MunicipalCrewEntity>>> getAvailableCrews() async => Success(List.from(crews));

  @override
  Future<Result<MunicipalCrewEntity>> createCrew(MunicipalCrewEntity crew) async {
    final created = crew.copyWith(id: 'crew-${crews.length + 1}');
    crews.insert(0, created);
    return Success(created);
  }

  @override
  Future<Result<MunicipalCrewEntity>> updateCrew(MunicipalCrewEntity crew) async {
    final index = crews.indexWhere((c) => c.id == crew.id);
    if (index >= 0) {
      crews[index] = crew;
    }
    return Success(crew);
  }

  @override
  Future<Result<void>> deleteCrew(String crewId) async {
    crews.removeWhere((c) => c.id == crewId);
    return const Success(null);
  }

  @override
  Future<Result<ReportEntity>> assignReportToCrew({
    required String reportId,
    required MunicipalCrewEntity crew,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<ReportEntity>> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<UserEntity>>> getStaffMembers() async => const Success([]);

  @override
  Future<Result<UserEntity?>> searchUserByExactEmail(String email) async => const Success(null);

  @override
  Future<Result<void>> updateUserRole({
    required String userId,
    required UserRole newRole,
    String? teamId,
  }) async => const Success(null);
}

final testAdminUser = UserEntity(
  id: 'admin-1',
  name: 'Ing. Supervisor',
  email: 'admin@ecoroute.com',
  role: UserRole.admin,
  createdAt: DateTime(2025, 1, 1),
);

final testCrews = [
  const MunicipalCrewEntity(
    id: 'crew-1',
    name: 'Cuadrilla Zona Norte',
    zone: 'Sector 1 (Los Próceres)',
    leadStaffName: 'Mario Limpieza',
    vehicleCode: 'Camión #04',
    vehiclePlate: 'ECR-882',
    vehicleType: 'Camión Compactador 15m³',
    crewMembersCount: 3,
    activeTasksCount: 2,
    isAvailable: true,
    status: MunicipalCrewStatus.onRoute,
    latitude: -12.0410,
    longitude: -77.0390,
  ),
  const MunicipalCrewEntity(
    id: 'crew-2',
    name: 'Cuadrilla Especial Desbordes',
    zone: 'Todos los sectores',
    leadStaffName: 'Jorge Parque',
    vehicleCode: 'Camión #05',
    vehiclePlate: 'ECR-554',
    vehicleType: 'Camión Volquete Pesado',
    crewMembersCount: 3,
    activeTasksCount: 0,
    isAvailable: true,
    status: MunicipalCrewStatus.available,
    latitude: -12.0480,
    longitude: -77.0360,
  ),
];

void main() {
  testWidgets('Renderiza AdminCrewsScreen con métricas de flota, chips y listado de unidades',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = MockAdminCrewsRepository()..crews = List.from(testCrews);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminCrewsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Título y encabezado
    expect(find.text('Cuadrillas Operativas'), findsOneWidget);
    expect(find.textContaining('equipos registrados'), findsOneWidget);

    // 2. Métricas de cuadrillas
    expect(find.text('Total Equipos'), findsOneWidget);
    expect(find.text('En Ruta'), findsWidgets);
    expect(find.text('Disponibles'), findsWidgets);
    expect(find.text('Incidencias'), findsWidgets);

    // 3. Tarjetas de Cuadrilla
    expect(find.byType(AdminCrewCard), findsNWidgets(2));
    expect(find.text('Cuadrilla Zona Norte'), findsOneWidget);
    expect(find.text('Cuadrilla Especial Desbordes'), findsOneWidget);
    expect(find.textContaining('ECR-882'), findsOneWidget);
    expect(find.textContaining('ECR-554'), findsOneWidget);

    // 4. Barra inferior de navegación
    expect(find.byType(AdminBottomNavBar), findsOneWidget);
    expect(find.text('Cuadrillas'), findsOneWidget);
  });

  testWidgets('Filtra cuadrillas al escribir en el buscador de AdminCrewsScreen', (tester) async {
    final mockRepo = MockAdminCrewsRepository()..crews = List.from(testCrews);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminCrewsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Escribir en el buscador
    final searchInput = find.byType(TextField);
    expect(searchInput, findsOneWidget);
    await tester.enterText(searchInput, 'Norte');
    await tester.pumpAndSettle();

    // Solo debe coincidir Cuadrilla Zona Norte
    expect(find.text('Cuadrilla Zona Norte'), findsOneWidget);
    expect(find.text('Cuadrilla Especial Desbordes'), findsNothing);
  });

  testWidgets('Abre modal de gestión de unidad y permite guardar cambios', (tester) async {
    final mockRepo = MockAdminCrewsRepository()..crews = List.from(testCrews);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminCrewsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Presionar botón "Gestionar" en la primera tarjeta
    final manageButtons = find.text('Gestionar');
    expect(manageButtons, findsWidgets);
    await tester.tap(manageButtons.first);
    await tester.pumpAndSettle();

    // Verificar modal abierto
    expect(find.byType(AdminCrewEditModal), findsOneWidget);
    expect(find.text('Gestionar Cuadrilla Zona Norte'), findsOneWidget);
    expect(find.text('Sector de Cobertura Asignado'), findsOneWidget);

    // Presionar guardar
    final saveButton = find.text('Guardar Cambios de Unidad');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Modal se cierra
    expect(find.byType(AdminCrewEditModal), findsNothing);
  });

  testWidgets('Abre modal de creación con FAB y permite registrar una nueva cuadrilla', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = MockAdminCrewsRepository()..crews = List.from(testCrews);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminCrewsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verificar FAB
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    expect(find.text('Nueva Cuadrilla'), findsOneWidget);

    // 2. Tocar FAB
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // 3. Modal abierto
    expect(find.byType(AdminCrewCreateModal), findsOneWidget);
    expect(find.text('Registrar Nueva Cuadrilla'), findsOneWidget);

    // 4. Llenar formulario
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(5));

    await tester.enterText(textFields.at(0), 'Cuadrilla Surquillo');
    await tester.enterText(textFields.at(1), 'Sector 6 (Av. Principal)');
    await tester.enterText(textFields.at(2), 'Roberto Gómez');
    await tester.enterText(textFields.at(3), 'Camión #07');
    await tester.enterText(textFields.at(4), 'ECR-999');
    await tester.pumpAndSettle();

    // 5. Presionar guardar
    final registerButton = find.text('Registrar Cuadrilla en Firestore');
    expect(registerButton, findsOneWidget);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    // 6. Modal cerrado y cuadrilla agregada a la lista
    expect(find.byType(AdminCrewCreateModal), findsNothing);
    expect(find.text('Cuadrilla Surquillo'), findsOneWidget);
  });

  testWidgets('Abre modal de gestión y permite dar de baja una cuadrilla con diálogo de confirmación', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = MockAdminCrewsRepository()..crews = List.from(testCrews);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminCrewsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Abrir modal de gestión
    final manageButtons = find.text('Gestionar');
    expect(manageButtons, findsWidgets);
    await tester.tap(manageButtons.first);
    await tester.pumpAndSettle();

    // 2. Presionar "Dar de baja cuadrilla"
    final deleteButton = find.text('Dar de baja cuadrilla');
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // 3. Verificar diálogo de confirmación
    expect(find.text('Confirmar baja de unidad'), findsOneWidget);
    final confirmDeleteButton = find.widgetWithText(ElevatedButton, 'Eliminar');
    expect(confirmDeleteButton, findsOneWidget);
    await tester.tap(confirmDeleteButton);
    await tester.pumpAndSettle();

    // 4. Se eliminó de la lista
    expect(find.byType(AdminCrewEditModal), findsNothing);
    expect(find.text('Cuadrilla Zona Norte'), findsNothing);
    expect(find.text('Cuadrilla Especial Desbordes'), findsOneWidget);
  });
}
