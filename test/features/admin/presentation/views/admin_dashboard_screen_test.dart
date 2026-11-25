import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ecoroute/core/router/app_router.dart';
import 'package:ecoroute/core/router/route_names.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/admin/domain/entities/admin_report_page.dart';
import 'package:ecoroute/features/admin/domain/entities/municipal_crew_entity.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_profile_repository.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_state.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_viewmodel.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_dashboard_screen.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_profile_screen.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';

import '../../admin_report_fixtures.dart';

class MockAdminAuthViewModel extends AuthViewModel {
  final UserEntity? testUser;
  int logoutCalls = 0;
  String? resetEmail;
  MockAdminAuthViewModel(this.testUser);

  @override
  AuthState build() {
    return AuthState(user: testUser, isInitialized: true);
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    resetEmail = email;
    return true;
  }
}

class MockAdminProfileRepository implements AdminProfileRepository {
  String? requestedEmail;
  String? confirmedEmail;

  @override
  Future<Result<UserEntity>> saveContact(
    UserEntity account, {
    required String name,
    required String? phone,
  }) async => Success(account.copyWith(name: name, phoneNumber: phone));

  @override
  Future<Result<void>> requestEmailChange(
    String uid, {
    required String email,
    required String password,
  }) async {
    requestedEmail = email;
    return const Success(null);
  }

  @override
  Future<Result<String>> refreshEmail(String uid) async =>
      Success(confirmedEmail ?? testAdminUser.email);
}

class MockAdminRepository implements AdminRepository {
  List<ReportEntity> reports = [];
  List<MunicipalCrewEntity> crews = [];

  @override
  Future<Result<AdminReportPage<ReportEntity>>> getReportsPage({
    AdminReportCursor? after,
  }) async => Success(AdminReportPage(reports));

  @override
  Future<Result<AdminReportTotals>> getReportTotals() async =>
      Success(totalsForReports(reports));

  @override
  Future<Result<List<MunicipalCrewEntity>>> getAvailableCrews() async {
    return Success(crews);
  }

  @override
  Future<Result<MunicipalCrewEntity>> createCrew(
    MunicipalCrewEntity crew,
  ) async => Success(crew);

  @override
  Future<Result<MunicipalCrewEntity>> updateCrew(
    MunicipalCrewEntity crew,
  ) async => Success(crew);

  @override
  Future<Result<void>> deleteVehicle(String vehicleId) async =>
      const Success(null);

  @override
  Future<Result<void>> deleteCrew(String crewId) async => const Success(null);

  @override
  Future<Result<List<ReportEntity>>> getCrewActiveReports(String crewId) async =>
      const Success([]);

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
  Future<Result<List<UserEntity>>> getStaffMembers() async => const Success([]);

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
  name: 'Ing. Marco Municipal',
  email: 'marco@ecoroute.com',
  role: UserRole.admin,
  createdAt: DateTime(2025, 1, 1),
);

final testReports = [
  ReportEntity(
    id: 'rep-1',
    reportNumber: '#REP-1001',
    citizenId: 'c-1',
    citizenName: 'Vecino 1',
    categoryId: 'waste',
    categoryName: 'Acumulación de basura',
    categoryIcon: 'delete_outline_rounded',
    description: 'Bolsas acumuladas',
    priority: ReportPriority.high,
    status: ReportStatus.pending,
    latitude: -12.04,
    longitude: -77.04,
    address: 'Av. Grau 120',
    imageUrls: const [],
    createdAt: DateTime.now(),
  ),
  ReportEntity(
    id: 'rep-2',
    reportNumber: '#REP-1002',
    citizenId: 'c-2',
    citizenName: 'Vecino 2',
    categoryId: 'bin',
    categoryName: 'Contenedor lleno',
    categoryIcon: 'delete_sweep_rounded',
    description: 'Contenedor lleno',
    priority: ReportPriority.medium,
    status: ReportStatus.resolved,
    latitude: -12.05,
    longitude: -77.03,
    address: 'Av. Tacna 450',
    imageUrls: const [],
    createdAt: DateTime.now(),
  ),
];

void main() {
  testWidgets('El perfil guarda los datos y muestra el correo después de confirmarlo', (tester) async {
    final profile = MockAdminProfileRepository();
    final auth = MockAdminAuthViewModel(testAdminUser);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => auth),
          adminProfileRepositoryProvider.overrideWithValue(profile),
        ],
        child: const MaterialApp(home: AdminProfileScreen()),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'Marco Actualizado');
    await tester.enterText(find.byType(TextFormField).last, '987654321');
    await tester.tap(find.text('Guardar datos'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(AdminProfileScreen)));
    expect(container.read(authViewModelProvider).user?.name, 'Marco Actualizado');
    expect(container.read(authViewModelProvider).user?.phoneNumber, '987654321');

    await tester.ensureVisible(find.text('Cambiar correo'));
    await tester.tap(find.text('Cambiar correo'));
    await tester.pumpAndSettle();
    final dialogFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextFormField));
    await tester.enterText(dialogFields.first, 'nuevo@example.com');
    await tester.enterText(dialogFields.last, 'contraseña local');
    await tester.tap(find.text('Enviar confirmación'));
    await tester.pumpAndSettle();
    expect(profile.requestedEmail, 'nuevo@example.com');
    expect(container.read(authViewModelProvider).user?.email, testAdminUser.email);

    profile.confirmedEmail = profile.requestedEmail;
    final refresh = find.byTooltip('Comprobar correo confirmado');
    await tester.ensureVisible(refresh);
    await tester.tap(refresh);
    await tester.pumpAndSettle();
    expect(find.text('nuevo@example.com'), findsOneWidget);
  });

  testWidgets('El menú principal abre la sección elegida directamente', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authViewModelProvider.overrideWith(
          () => MockAdminAuthViewModel(testAdminUser),
        ),
        adminRepositoryProvider.overrideWithValue(MockAdminRepository()),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> selectTab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(AdminBottomNavBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    await selectTab('Reportes');
    await selectTab('Equipo');
    await selectTab('Inicio');
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    expect(router.canPop(), isFalse);

    for (final (label, path) in [
      ('Mapa', RouteNames.adminLiveMap),
      ('Equipo', RouteNames.adminTeams),
      ('Reportes', RouteNames.adminReports),
    ]) {
      await selectTab(label);
      expect(router.routeInformationProvider.value.uri.path, path);
      expect(router.canPop(), isFalse);
    }

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardScreen), findsOneWidget);

    await selectTab('Equipo');
    await tester.tap(find.text('Flota'));
    await tester.pumpAndSettle();
    expect(find.text('Flota Vehicular'), findsOneWidget);
    await selectTab('Equipo');
    expect(find.widgetWithText(AppBar, 'Equipos'), findsOneWidget);
    expect(router.canPop(), isFalse);

    await tester.tap(find.text('Personal'));
    await tester.pumpAndSettle();
    expect(find.text('Gestión de Personal'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Equipos'), findsOneWidget);
  });

  testWidgets(
    'Renderiza AdminDashboardScreen con métricas vivas y módulos de gestión',
    (tester) async {
      final mockRepo = MockAdminRepository()..reports = List.from(testReports);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(
              () => MockAdminAuthViewModel(testAdminUser),
            ),
            adminRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Panel municipal'), findsOneWidget);
      expect(find.byTooltip('Abrir menú de cuenta'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsNothing);
      expect(find.text('Ing. Marco Municipal'), findsNothing);
      expect(find.text('Reportes pendientes'), findsOneWidget);
      expect(find.text('Ver pendientes'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('En proceso'), findsOneWidget);
      expect(find.text('Resueltos'), findsOneWidget);
      expect(find.text('Operación'), findsOneWidget);
      expect(find.text('Flota'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Por atender'), findsOneWidget);
      expect(find.text('Av. Grau 120'), findsOneWidget);

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
      expect(find.text('Mapa'), findsOneWidget);
      expect(find.text('Equipo'), findsOneWidget);
    },
  );

  testWidgets(
    'El menú abre datos y restablecimiento de contraseña y confirma el cierre de sesión',
    (tester) async {
      final auth = MockAdminAuthViewModel(testAdminUser);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(() => auth),
            adminRepositoryProvider.overrideWithValue(MockAdminRepository()),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> openMenu() async {
        await tester.tap(find.byTooltip('Abrir menú de cuenta'));
        await tester.pumpAndSettle();
      }

      await openMenu();
      expect(find.text('Ing. Marco Municipal'), findsOneWidget);
      expect(find.text('marco@ecoroute.com'), findsOneWidget);
      await tester.tap(find.text('Mi perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Guardar datos'), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await openMenu();
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar enlace de restablecimiento'));
      await tester.pumpAndSettle();
      expect(auth.resetEmail, testAdminUser.email);

      await openMenu();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
      expect(auth.logoutCalls, 0);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(auth.logoutCalls, 0);

      await openMenu();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(auth.logoutCalls, 1);
    },
  );

  testWidgets(
    'Los accesos abren la bandeja filtrada, el detalle y los módulos operativos',
    (tester) async {
      final repository = MockAdminRepository()..reports = List.of(testReports);
      final container = ProviderContainer(
        overrides: [
          authViewModelProvider.overrideWith(
            () => MockAdminAuthViewModel(testAdminUser),
          ),
          adminRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: RouteNames.adminDashboard,
        routes: [
          GoRoute(
            path: RouteNames.adminDashboard,
            builder: (_, _) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.adminReports,
            builder: (_, _) => const Scaffold(body: Text('Bandeja municipal')),
          ),
          GoRoute(
            path: RouteNames.adminReportDetail,
            builder: (_, state) =>
                Scaffold(body: Text('Detalle: ${state.pathParameters['id']}')),
          ),
          GoRoute(
            path: RouteNames.adminFleet,
            builder: (_, _) => const Scaffold(body: Text('Módulo flota')),
          ),
          GoRoute(
            path: RouteNames.adminStaff,
            builder: (_, _) => const Scaffold(body: Text('Módulo personal')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver pendientes'));
      await tester.pumpAndSettle();
      expect(find.text('Bandeja municipal'), findsOneWidget);
      expect(
        container.read(adminReportsViewModelProvider).selectedFilter,
        AdminReportFilter.pending,
      );
      router.pop();
      await tester.pumpAndSettle();

      for (final (label, destination) in [
        ('Acumulación de basura', 'Detalle: rep-1'),
        ('Flota', 'Módulo flota'),
        ('Personal', 'Módulo personal'),
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.text(destination), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
      }
    },
  );
}
