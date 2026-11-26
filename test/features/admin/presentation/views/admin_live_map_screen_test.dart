import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ecoroute/core/router/app_router.dart';
import 'package:ecoroute/core/router/route_names.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/admin/domain/entities/admin_report_page.dart';
import 'package:ecoroute/features/admin/domain/entities/municipal_crew_entity.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_viewmodel.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_live_map_screen.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_map_crew_preview_card.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_map_report_preview_card.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';

import '../../admin_report_fixtures.dart';

class MockAdminAuthViewModel extends AuthViewModel {
  final UserEntity? testUser;
  final bool restoresSession;
  MockAdminAuthViewModel(this.testUser, {this.restoresSession = false});

  @override
  AuthState build() {
    return restoresSession
        ? AuthState.initial()
        : AuthState(user: testUser, isInitialized: true);
  }

  void restoreSession() {
    state = AuthState(user: testUser, isInitialized: true);
  }
}

class MockAdminMapRepository implements AdminRepository {
  List<ReportEntity> reports = [];
  List<ReportEntity> nextPage = [];
  List<MunicipalCrewEntity> crews = [];

  @override
  Future<Result<AdminReportPage<ReportEntity>>> getReportsPage({
    AdminReportCursor? after,
  }) async => Success(
    after == null
        ? AdminReportPage(
            reports,
            nextCursor: nextPage.isEmpty ? null : _NextPage(),
          )
        : AdminReportPage(nextPage),
  );

  @override
  Future<Result<AdminReportTotals>> getReportTotals() async => Success(totalsForReports(reports));

  @override
  Future<Result<List<MunicipalCrewEntity>>> getAvailableCrews() async => Success(crews);

  @override
  Future<Result<MunicipalCrewEntity>> createCrew(MunicipalCrewEntity crew) async => Success(crew);

  @override
  Future<Result<MunicipalCrewEntity>> updateCrew(MunicipalCrewEntity crew) async => Success(crew);

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
    final idx = reports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      final updated = reports[idx].copyWith(
        status: ReportStatus.assigned,
        assignedToTeamId: crew.id,
        assignedToTeamName: crew.name,
      );
      reports[idx] = updated;
      return Success(updated);
    }
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

class _NextPage implements AdminReportCursor {}

final testAdminUser = UserEntity(
  id: 'admin-1',
  name: 'Ing. Supervisor',
  email: 'admin@ecoroute.com',
  role: UserRole.admin,
  createdAt: DateTime(2025, 1, 1),
);

final testMapReports = [
  ReportEntity(
    id: 'rep-m1',
    reportNumber: '#REP-0101',
    citizenId: 'c-1',
    citizenName: 'Vecino Lima',
    categoryId: 'waste',
    categoryName: 'Acumulación de basura',
    categoryIcon: 'delete_outline_rounded',
    description: 'Bolsas acumuladas en esquina',
    priority: ReportPriority.high,
    status: ReportStatus.pending,
    latitude: -7.151,
    longitude: -78.527,
    address: 'Jr. Carabaya 450',
    imageUrls: const [],
    createdAt: DateTime.now(),
  ),
  ReportEntity(
    id: 'rep-m2',
    reportNumber: '#REP-0102',
    citizenId: 'c-2',
    citizenName: 'Vecina Centro',
    categoryId: 'bin',
    categoryName: 'Contenedor lleno',
    categoryIcon: 'delete_sweep_rounded',
    description: 'Contenedor saturado',
    priority: ReportPriority.medium,
    status: ReportStatus.inProgress,
    latitude: -7.148,
    longitude: -78.496,
    address: 'Av. Tacna 210',
    imageUrls: const [],
    createdAt: DateTime.now(),
  ),
];

final testMapCrews = [
  const MunicipalCrewEntity(
    id: 'crew-1',
    name: 'Cuadrilla Centro Histórico',
    zone: 'Sector 1',
    leadStaffName: 'Rosa Operaria',
    vehicleCode: 'Camión #01',
    vehiclePlate: 'ECR-119',
    activeTasksCount: 2,
    isAvailable: true,
    latitude: -7.162,
    longitude: -78.518,
  ),
];

void main() {
  testWidgets(
    'Renderiza AdminLiveMapScreen con filtros de capa y barra inferior',
    (tester) async {
      final mockRepo = MockAdminMapRepository()
        ..reports = List.from(testMapReports)
        ..crews = List.from(testMapCrews);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(
              () => MockAdminAuthViewModel(testAdminUser),
            ),
            adminRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: AdminLiveMapScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Título y métricas
      expect(find.text('Mapa de Monitoreo Urbano'), findsOneWidget);
      expect(find.textContaining('incidencias'), findsOneWidget);

      // 2. Filtros superiores
      expect(find.text('Todos (2)'), findsOneWidget);
      expect(find.text('Urgentes (1)'), findsOneWidget);
      expect(find.text('Pendientes (1)'), findsOneWidget);
      expect(find.text('Personal (1)'), findsOneWidget);

      // 3. Menú inferior con tab activo
      expect(find.byType(AdminBottomNavBar), findsOneWidget);
      expect(find.text('Mapa'), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
      expect(find.text('Equipo'), findsOneWidget);
    },
  );

  testWidgets(
    'Permite alternar filtros y seleccionar reporte para ver tarjeta emergente',
    (tester) async {
      final mockRepo = MockAdminMapRepository()
        ..reports = List.from(testMapReports)
        ..crews = List.from(testMapCrews);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(
              () => MockAdminAuthViewModel(testAdminUser),
            ),
            adminRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: AdminLiveMapScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final selectReportBtn = find.text('#REP-0101');
      expect(selectReportBtn, findsOneWidget);
      await tester.tap(selectReportBtn);
      await tester.pumpAndSettle();

      // Verificar que se abre la tarjeta de vista previa
      expect(find.byType(AdminMapReportPreviewCard), findsOneWidget);
      expect(find.text('Acumulación de basura'), findsOneWidget);
      expect(find.text('Jr. Carabaya 450'), findsOneWidget);
      expect(find.text('Asignar'), findsOneWidget);

      // Cerrar la tarjeta de vista previa
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(AdminMapReportPreviewCard), findsNothing);
    },
  );

  testWidgets(
    'Permite seleccionar cuadrilla para ver tarjeta de operario y camión',
    (tester) async {
      final mockRepo = MockAdminMapRepository()
        ..reports = List.from(testMapReports)
        ..crews = List.from(testMapCrews);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(
              () => MockAdminAuthViewModel(testAdminUser),
            ),
            adminRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: AdminLiveMapScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final selectCrewBtn = find.text('Camión #01');
      expect(selectCrewBtn, findsOneWidget);
      await tester.tap(selectCrewBtn);
      await tester.pumpAndSettle();

      // Verificar tarjeta de cuadrilla
      expect(find.byType(AdminMapCrewPreviewCard), findsOneWidget);
      expect(find.text('Cuadrilla Centro Histórico'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AdminMapCrewPreviewCard),
          matching: find.textContaining('Camión #01'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('ECR-119'), findsOneWidget);
      expect(find.text('Ver Reportes Asignados'), findsOneWidget);
    },
  );

  testWidgets(
    'Un sector del mapa abre su listado con el total de todas las páginas',
    (tester) async {
      final central = testMapReports.first.copyWith(
        id: 'central-1',
        reportNumber: '#CENTRAL-01',
        latitude: -7.158,
        longitude: -78.518,
      );
      final later = central.copyWith(
        id: 'central-2',
        reportNumber: '#CENTRAL-02',
      );
      final outside = central.copyWith(
        id: 'outside',
        reportNumber: '#FUERA',
        latitude: -7.166,
        longitude: -78.454,
      );
      final repo = MockAdminMapRepository()
        ..reports = [central, testMapReports.first, outside]
        ..nextPage = [later];
      final container = ProviderContainer.test(
        overrides: [
          authViewModelProvider.overrideWith(
            () => MockAdminAuthViewModel(testAdminUser),
          ),
          adminRepositoryProvider.overrideWithValue(repo),
        ],
      );
      final dispatcher = tester.binding.platformDispatcher;
      dispatcher.defaultRouteNameTestValue = RouteNames.adminLiveMap;
      addTearDown(dispatcher.clearDefaultRouteNameTestValue);
      final router = container.read(routerProvider);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('#FUERA'), findsNothing);

      final map = find.byType(FlutterMap);
      final controller = tester.widget<FlutterMap>(map).mapController!;
      final position = controller.camera.latLngToScreenPoint(
        const LatLng(-7.164, -78.510),
      );
      await tester.tapAt(
        tester.getTopLeft(map) + Offset(position.x, position.y),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Zona Central'), findsOneWidget);
      expect(find.text('2 reportes'), findsOneWidget);
      await tester.tap(find.text('Ver todos'));
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.queryParameters['zona'],
        'central',
      );
      expect(find.text('Reportes: Zona Central'), findsOneWidget);
      expect(find.text('#CENTRAL-01'), findsOneWidget);
      expect(find.text('#CENTRAL-02'), findsOneWidget);
      expect(find.text(testMapReports.first.reportNumber), findsNothing);
      expect(find.text('#FUERA'), findsNothing);
    },
  );

  testWidgets('Conserva el enlace de zona al recuperar la sesión', (tester) async {
    final auth = MockAdminAuthViewModel(testAdminUser, restoresSession: true);
    final repo = MockAdminMapRepository();
    final container = ProviderContainer.test(
      overrides: [
        authViewModelProvider.overrideWith(() => auth),
        adminRepositoryProvider.overrideWithValue(repo),
      ],
    );
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.defaultRouteNameTestValue = RouteNames.adminReportsByZone('noreste');
    addTearDown(dispatcher.clearDefaultRouteNameTestValue);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    auth.restoreSession();
    await tester.pumpAndSettle();
    expect(find.text('Reportes: Zona Noreste'), findsOneWidget);
  });
}
