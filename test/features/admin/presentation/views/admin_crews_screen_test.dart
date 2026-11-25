import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ecoroute/core/router/route_names.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/admin/domain/entities/admin_report_page.dart';
import 'package:ecoroute/features/admin/domain/entities/municipal_crew_entity.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_viewmodel.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_crews_screen.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_live_map_screen.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_crew_card.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_map_crew_preview_card.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_crew_editor_screen.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';

import '../../admin_report_fixtures.dart';

class MockAdminAuthViewModel extends AuthViewModel {
  final UserEntity? testUser;
  MockAdminAuthViewModel(this.testUser);

  @override
  AuthState build() {
    return AuthState(user: testUser, isInitialized: true);
  }
}

class MockAdminCrewsRepository implements AdminRepository {
  List<ReportEntity> reports = [];
  List<ReportEntity> crewReports = [];
  List<MunicipalCrewEntity> crews = [];

  @override
  Future<Result<AdminReportPage<ReportEntity>>> getReportsPage({
    AdminReportCursor? after,
  }) async => Success(AdminReportPage(reports));

  @override
  Future<Result<AdminReportTotals>> getReportTotals() async =>
      Success(totalsForReports(reports));

  @override
  Future<Result<List<MunicipalCrewEntity>>> getAvailableCrews() async =>
      Success(List.from(crews));

  @override
  Future<Result<MunicipalCrewEntity>> createCrew(
    MunicipalCrewEntity crew,
  ) async {
    final created = crew.copyWith(id: 'crew-${crews.length + 1}');
    crews.insert(0, created);
    return Success(created);
  }

  @override
  Future<Result<MunicipalCrewEntity>> updateCrew(
    MunicipalCrewEntity crew,
  ) async {
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
  Future<Result<List<ReportEntity>>> getCrewActiveReports(
    String crewId,
  ) async => Success(
    crewReports.where((item) => item.assignedToTeamId == crewId).toList(),
  );

  @override
  Future<Result<Set<String>>> getBusyStaffIds() async => const Success({});

  @override
  Future<Result<ReportEntity>> assignReportToStaff({
    required String reportId,
    required List<String> staffIds,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  }) async => throw UnimplementedError();

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
  Future<Result<List<UserEntity>>> getStaffMembers() async => Success([
    for (final (id, name, team) in [
      ('1', 'Rosa Silva', 'crew-1'),
      ('2', 'Juan Ruiz', 'crew-1'),
      ('3', 'Ana Luna', null),
      ('4', 'Luis Torres', null),
      ('5', 'Clara Soto', null),
      ('6', 'Jorge Ríos', null),
      ('7', 'Marta Díaz', null),
      ('8', 'Paula León', null),
    ])
      UserEntity(
        id: id,
        name: name,
        email: '$id@example.com',
        role: UserRole.staff,
        createdAt: DateTime(2025),
        teamId: team,
      ),
  ]);

  @override
  Future<Result<UserEntity?>> searchUserByExactEmail(String email) async =>
      const Success(null);

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
  testWidgets(
    'Muestra el reporte asignado y abre el mapa en el equipo correcto',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final mockRepo = MockAdminCrewsRepository()
        ..crews = List.from(testCrews)
        ..crewReports = [
          ReportEntity(
            id: 'old-report',
            reportNumber: 'REP-100',
            citizenId: 'citizen',
            citizenName: 'Vecino',
            categoryId: 'waste',
            categoryName: 'Acumulación de residuos',
            categoryIcon: 'delete',
            description: 'Residuos en el sector',
            priority: ReportPriority.medium,
            status: ReportStatus.assigned,
            latitude: -12.04,
            longitude: -77.04,
            address: 'Sector 1',
            imageUrls: const [],
            createdAt: DateTime(2025),
            assignedToTeamId: 'crew-1',
          ),
        ];
      final router = GoRouter(
        initialLocation: RouteNames.adminTeams,
        routes: [
          GoRoute(
            path: RouteNames.adminTeams,
            builder: (_, _) => const AdminCrewsScreen(),
          ),
          GoRoute(
            path: RouteNames.adminLiveMap,
            builder: (_, state) => AdminLiveMapScreen(
              initialCrewId: state.uri.queryParameters['teamId'],
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(
              () => MockAdminAuthViewModel(testAdminUser),
            ),
            adminRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cuadrilla Zona Norte'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('REP-100', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.text('Ver en mapa'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AdminMapCrewPreviewCard>(
              find.byType(AdminMapCrewPreviewCard),
            )
            .crew
            .id,
        'crew-1',
      );
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Detalle del equipo'), findsOneWidget);
    },
  );

  testWidgets(
    'Permite editar datos generales de un equipo anterior de una persona',
    (tester) async {
      final legacy = testCrews.first.copyWith(
        crewMembersCount: 1,
        memberIds: const ['1'],
        latitude: 0,
        longitude: 0,
      );
      final mockRepo = MockAdminCrewsRepository()..crews = [legacy];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(
              () => MockAdminAuthViewModel(testAdminUser),
            ),
            adminRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: AdminCrewsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(legacy.name));
      await tester.pumpAndSettle();
      expect(find.text('Ver en mapa'), findsNothing);
      await tester.tap(find.text('Editar equipo'));
      await tester.pumpAndSettle();
      expect(find.text('Integrantes (1)'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Equipo Norte');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(mockRepo.crews.single.crewMembersCount, 1);
      expect(mockRepo.crews.single.name, 'Equipo Norte');
    },
  );

  testWidgets('Muestra el listado compacto con buscador y filtros', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = MockAdminCrewsRepository()..crews = List.from(testCrews);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(
            () => MockAdminAuthViewModel(testAdminUser),
          ),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(home: AdminCrewsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Título y encabezado
    expect(find.text('Equipos'), findsOneWidget);
    expect(find.text('Total Equipos'), findsNothing);
    expect(find.text('En Ruta'), findsWidgets);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Gestionar'), findsNothing);

    // 3. Tarjetas de Cuadrilla
    expect(find.byType(AdminCrewCard), findsNWidgets(2));
    expect(find.text('Cuadrilla Zona Norte'), findsOneWidget);
    expect(find.text('Cuadrilla Especial Desbordes'), findsOneWidget);
    expect(find.textContaining('ECR-882'), findsOneWidget);
    expect(find.textContaining('ECR-554'), findsOneWidget);

    // 4. Barra inferior de navegación
    expect(find.byType(AdminBottomNavBar), findsOneWidget);
    expect(find.text('Equipo'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'En Ruta'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminCrewCard), findsOneWidget);
    expect(find.text('Cuadrilla Zona Norte'), findsOneWidget);
  });

  testWidgets(
    'Filtra cuadrillas al escribir en el buscador de AdminCrewsScreen',
    (tester) async {
      final mockRepo = MockAdminCrewsRepository()..crews = List.from(testCrews);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(
              () => MockAdminAuthViewModel(testAdminUser),
            ),
            adminRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: AdminCrewsScreen()),
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
    },
  );

  testWidgets(
    'Abre el detalle y permite editar el equipo con los datos precargados',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final mockRepo = MockAdminCrewsRepository()
        ..crews = [
          testCrews.first.copyWith(
            activeTasksCount: 0,
            status: MunicipalCrewStatus.available,
            crewMembersCount: 2,
          ),
          ...testCrews.skip(1),
        ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(
              () => MockAdminAuthViewModel(testAdminUser),
            ),
            adminRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: AdminCrewsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Cuadrilla Zona Norte'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle del equipo'), findsOneWidget);
      expect(find.text('Rosa Silva'), findsOneWidget);
      expect(find.text('Ver en mapa'), findsOneWidget);

      await tester.tap(find.text('Editar equipo'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminCrewEditorScreen), findsOneWidget);
      expect(find.text('Sector'), findsOneWidget);
      expect(find.text('Integrantes (2)'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Cuadrilla Norte',
      );

      final saveButton = find.text('Guardar cambios');
      expect(saveButton, findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Guardar cambios'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.enterText(find.byType(TextField).last, '3@example.com');
      await tester.pumpAndSettle();
      final newcomer = find.widgetWithText(ListTile, 'Ana Luna');
      await tester.ensureVisible(newcomer);
      await tester.tap(newcomer);
      await tester.pumpAndSettle();
      expect(find.text('Integrantes (3)'), findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.byType(AdminCrewEditorScreen), findsNothing);
      expect(find.text('Cuadrilla Norte'), findsOneWidget);
      expect(mockRepo.crews.first.crewMembersCount, 3);
    },
  );

  testWidgets(
    'Crea un equipo desde el formulario y valida su tamaño en pantalla móvil',
    (tester) async {
      tester.view.physicalSize = const Size(390, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockAdminCrewsRepository()
        ..crews = [
          ...testCrews,
          const MunicipalCrewEntity(
            id: 'truck-3',
            name: 'Camión libre',
            zone: 'General',
            leadStaffName: 'Sin conductor',
            vehicleCode: 'Camión libre',
            vehiclePlate: 'ECR-999',
            vehicleOnly: true,
          ),
        ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(
              () => MockAdminAuthViewModel(testAdminUser),
            ),
            adminRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: AdminCrewsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verificar FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      expect(find.text('Nuevo equipo'), findsOneWidget);

      // 2. Tocar FAB
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.byType(AdminCrewEditorScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Nuevo equipo'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'Equipo Surquillo');
      await tester.enterText(fields.at(1), 'Sector Sur');
      await tester.tap(find.text('Seleccionar camión'));
      await tester.pumpAndSettle();
      final truck = find.widgetWithText(ListTile, 'Camión libre');
      await tester.ensureVisible(truck);
      await tester.tap(truck);
      await tester.pumpAndSettle();
      final members = find.byType(TextField).last;
      await tester.ensureVisible(members);
      expect(find.text('Tamaño del equipo'), findsNothing);
      final registerButton = find.widgetWithText(FilledButton, 'Crear equipo');
      expect(tester.widget<FilledButton>(registerButton).onPressed, isNull);
      expect(find.text('Ana Luna'), findsNothing);
      await tester.enterText(members, 'Luna');
      await tester.pumpAndSettle();
      expect(find.text('Luis Torres'), findsNothing);
      final ana = find.widgetWithText(ListTile, 'Ana Luna');
      await tester.ensureVisible(ana);
      await tester.tap(ana);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Quitar a Ana Luna'), findsOneWidget);
      expect(tester.widget<FilledButton>(registerButton).onPressed, isNull);
      await tester.tap(members);
      await tester.pumpAndSettle();
      expect(find.text('Rosa Silva'), findsNothing);
      final luis = find.widgetWithText(ListTile, 'Luis Torres');
      await tester.ensureVisible(luis);
      await tester.tap(luis);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(registerButton).onPressed, isNotNull);

      Future<void> addMember(String name) async {
        await tester.ensureVisible(members);
        await tester.enterText(members, name);
        await tester.pumpAndSettle();
        final candidate = find.widgetWithText(ListTile, name);
        await tester.ensureVisible(candidate);
        await tester.tap(candidate);
        await tester.pumpAndSettle();
      }

      for (final name in ['Clara Soto', 'Jorge Ríos', 'Marta Díaz']) {
        await addMember(name);
      }
      expect(find.text('Integrantes (5)'), findsOneWidget);
      expect(tester.widget<TextField>(members).enabled, isFalse);
      final remove = find.byTooltip('Quitar a Marta Díaz');
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(members).enabled, isTrue);
      await addMember('Paula León');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // 6. Modal cerrado y cuadrilla agregada a la lista
      expect(find.byType(AdminCrewEditorScreen), findsNothing);
      expect(find.text('Equipo Surquillo'), findsOneWidget);
      expect(mockRepo.crews.first.memberIds, ['3', '4', '5', '6', '8']);
    },
  );

  testWidgets('Elimina desde el menú del detalle después de confirmar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = MockAdminCrewsRepository()..crews = List.from(testCrews);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(
            () => MockAdminAuthViewModel(testAdminUser),
          ),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(home: AdminCrewsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Cuadrilla Zona Norte'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Más acciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar equipo'));
    await tester.pumpAndSettle();

    // 3. Verificar diálogo de confirmación
    expect(find.text('Eliminar equipo'), findsOneWidget);
    final confirmDeleteButton = find.widgetWithText(FilledButton, 'Eliminar');
    expect(confirmDeleteButton, findsOneWidget);
    await tester.tap(confirmDeleteButton);
    await tester.pumpAndSettle();

    // 4. Se eliminó de la lista
    expect(find.text('Detalle del equipo'), findsNothing);
    expect(find.text('Cuadrilla Zona Norte'), findsNothing);
    expect(find.text('Cuadrilla Especial Desbordes'), findsOneWidget);
  });
}
