import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/errors/exceptions.dart';
import 'package:ecoroute/core/errors/failures.dart';
import 'package:ecoroute/core/geo/cajamarca_urban_zones.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:ecoroute/features/admin/data/models/municipal_crew_dto.dart';
import 'package:ecoroute/features/admin/domain/entities/admin_report_page.dart';
import 'package:ecoroute/features/admin/domain/entities/municipal_crew_entity.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_viewmodel.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_reports_screen.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/data/models/report_dto.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';

import '../../admin_report_fixtures.dart';

class _TestReportCursor implements AdminReportCursor {}

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

class MockAdminRepository implements AdminRepository {
  List<ReportEntity> reports = [];
  List<MunicipalCrewEntity> crews = [];
  bool assignCalled = false;
  List<UserEntity> staff = [];
  List<String>? selectedStaffIds;
  Set<String> busyStaffIds = {};
  String? lastInstructions;
  Completer<Result<AdminReportPage<ReportEntity>>>? nextReportLoad;
  AdminReportCursor? firstCursor;
  List<ReportEntity> nextReports = [];
  bool failNextPage = false;
  int nextPageRequests = 0;

  @override
  Future<Result<AdminReportPage<ReportEntity>>> getReportsPage({AdminReportCursor? after}) async {
    if (after != null) {
      nextPageRequests++;
      expect(after, same(firstCursor));
      if (failNextPage) return const FailureResult(ServerFailure(message: 'Sin conexión'));
      return Success(AdminReportPage(nextReports));
    }
    final pending = nextReportLoad;
    nextReportLoad = null;
    return pending?.future ?? Success(AdminReportPage(List.of(reports), nextCursor: firstCursor));
  }

  @override
  Future<Result<AdminReportTotals>> getReportTotals() async =>
      Success(totalsForReports([...reports, ...nextReports.where((item) => !reports.contains(item))]));

  @override
  Future<Result<List<MunicipalCrewEntity>>> getAvailableCrews() async {
    return Success(crews);
  }

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
  Future<Result<Set<String>>> getBusyStaffIds() async => Success(busyStaffIds);

  @override
  Future<Result<ReportEntity>> assignReportToStaff({
    required String reportId,
    required List<String> staffIds,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  }) async {
    selectedStaffIds = staffIds;
    return Success(reports.first.copyWith(status: ReportStatus.assigned));
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
    assignCalled = true;
    lastInstructions = instructions;
    final index = reports.indexWhere((r) => r.id == reportId);
    if (index >= 0) {
      final updated = reports[index].copyWith(
        status: ReportStatus.assigned,
        priority: priority,
        assignedToTeamId: crew.id,
        assignedToTeamName: crew.name,
        assignedStaffName: crew.leadStaffName,
        assignedVehicle: '${crew.vehicleCode} • ${crew.vehiclePlate}',
      );
      reports[index] = updated;
      return Success(updated);
    }
    return const FailureResult(ServerFailure(message: 'No encontrado'));
  }

  @override
  Future<Result<ReportEntity>> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<UserEntity>>> getStaffMembers() async => Success(staff);

  @override
  Future<Result<UserEntity?>> searchUserByExactEmail(String email) async => const Success(null);

  @override
  Future<Result<void>> updateUserRole({
    required String userId,
    required UserRole newRole,
    String? teamId,
  }) async => const Success(null);
}

class _AdminRemoteSourceStub implements AdminRemoteDataSource {
  bool failReports = false;
  bool failCrews = false;
  List<ReportDto> reports = [];

  @override
  Future<AdminReportPage<ReportDto>> getReportsPage({AdminReportCursor? after}) async {
    if (failReports) {
      throw const ServerException(message: 'Firestore sin conexión', code: 'unavailable');
    }
    return AdminReportPage(reports);
  }

  @override
  Future<AdminReportTotals> getReportTotals() async {
    if (failReports) {
      throw const ServerException(message: 'Firestore sin conexión', code: 'unavailable');
    }
    return totalsForReports(reports.map((report) => report.toDomain()).toList());
  }

  @override
  Future<List<MunicipalCrewDto>> getAvailableCrews() async {
    if (failCrews) {
      throw const ServerException(message: 'Firestore sin conexión', code: 'unavailable');
    }
    return testCrews.map(MunicipalCrewDto.fromDomain).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final testAdminUser = UserEntity(
  id: 'admin-1',
  name: 'Ing. Supervisor Municipal',
  email: 'admin@ecoroute.com',
  role: UserRole.admin,
  createdAt: DateTime(2025, 1, 1),
);

final testReports = [
  ReportEntity(
    id: 'rep-test-1',
    reportNumber: '#REP-1024',
    citizenId: 'c-1',
    citizenName: 'María Mendoza',
    citizenPhone: '987 654 321',
    categoryId: 'waste_accumulation',
    categoryName: 'Acumulación de basura',
    categoryIcon: 'delete_outline_rounded',
    description: 'Montículo de bolsas plásticas en la acera.',
    priority: ReportPriority.high,
    status: ReportStatus.pending,
    latitude: -12.0478,
    longitude: -77.0415,
    address: 'Av. Abancay 450',
    imageUrls: const [],
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
  ),
  ReportEntity(
    id: 'rep-test-2',
    reportNumber: '#REP-2058',
    citizenId: 'c-2',
    citizenName: 'Luis Ramos',
    citizenPhone: '912 345 678',
    categoryId: 'full_bin',
    categoryName: 'Contenedor lleno',
    categoryIcon: 'delete_sweep_rounded',
    description: 'Contenedor desbordado.',
    priority: ReportPriority.medium,
    status: ReportStatus.assigned,
    latitude: -12.0452,
    longitude: -77.0435,
    address: 'Jr. de la Unión 810',
    imageUrls: const [],
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    assignedToTeamName: 'Cuadrilla Zona Norte',
    assignedVehicle: 'Camión #04 • ECR-882',
  ),
];

final testCrews = [
  const MunicipalCrewEntity(
    id: 'crew-1',
    name: 'Cuadrilla Zona Norte',
    zone: 'Sector 1 y 2',
    leadStaffName: 'Mario Limpieza',
    vehicleCode: 'Camión #04',
    vehiclePlate: 'ECR-882',
    activeTasksCount: 1,
  ),
  const MunicipalCrewEntity(
    id: 'crew-2',
    name: 'Cuadrilla Zona Sur',
    zone: 'Sector 3 y 4',
    leadStaffName: 'Carlos Cuadrilla',
    leaderId: 'member',
    vehicleCode: 'Camión #02',
    vehiclePlate: 'ECR-341',
    activeTasksCount: 0,
  ),
];

void main() {
  test('Reinicia el proveedor mientras sigue abierta una consulta anterior', () async {
    final repository = MockAdminRepository();
    final container = ProviderContainer.test(
      overrides: [adminRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(adminReportsViewModelProvider, (_, _) {});
    final viewModel = container.read(adminReportsViewModelProvider.notifier);
    await viewModel.refresh();

    final oldPage = Completer<Result<AdminReportPage<ReportEntity>>>();
    repository.nextReportLoad = oldPage;
    final oldLoad = viewModel.refresh();
    repository.reports = [testReports.last];
    container.invalidate(adminReportsViewModelProvider);
    final rebuilt = container.read(adminReportsViewModelProvider.notifier);
    await rebuilt.refresh();

    oldPage.complete(Success(AdminReportPage([testReports.first])));
    await oldLoad;
    final state = container.read(adminReportsViewModelProvider);
    expect(state.reports, [testReports.last]);
    expect(state.isLoading, isFalse);
  });

  test('Un despacho guardado se conserva aunque termine una consulta anterior', () async {
    final repository = MockAdminRepository()
      ..reports = List.of(testReports)
      ..crews = List.of(testCrews);
    final container = ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(adminReportsViewModelProvider, (_, _) {});
    final viewModel = container.read(adminReportsViewModelProvider.notifier);
    await viewModel.refresh();

    final previousReports = List.of(repository.reports);
    final pending = Completer<Result<AdminReportPage<ReportEntity>>>();
    repository.nextReportLoad = pending;
    final refresh = viewModel.refresh();
    expect(viewModel.refresh(), same(refresh));

    final assigned = await viewModel.assignReport(
      reportId: testReports.first.id,
      crew: testCrews.first,
      adminId: testAdminUser.id,
      adminName: testAdminUser.name,
    );
    expect(assigned, isTrue);

    pending.complete(Success(AdminReportPage(previousReports)));
    await refresh;

    final state = container.read(adminReportsViewModelProvider);
    expect(state.reports.first.status, ReportStatus.assigned);
    expect(state.isLoading, isFalse);
  });

  testWidgets('Distingue una falla inicial, datos anteriores y una carga vacía exitosa', (tester) async {
    final source = _AdminRemoteSourceStub()
      ..failReports = true
      ..failCrews = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRemoteDataSourceProvider.overrideWithValue(source),
        ],
        child: const MaterialApp(home: AdminReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.widgetWithText(TextButton, 'Reintentar');
    expect(find.textContaining('No se pudieron cargar los reportes.'), findsOneWidget);
    expect(find.textContaining('No se pudieron cargar los equipos.'), findsOneWidget);
    expect(find.textContaining('No hay reportes'), findsNothing);
    expect(find.text('0 incidencias cargadas'), findsNothing);

    source
      ..failReports = false
      ..reports = [ReportDto.fromDomain(testReports.first)];
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('#REP-1024'), findsOneWidget);
    expect(find.textContaining('No se pudieron cargar los reportes.'), findsNothing);
    expect(find.textContaining('No se pudieron cargar los equipos.'), findsOneWidget);
    expect(find.text('Asignar Personal'), findsNothing);

    source.failCrews = false;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(retry, findsNothing);

    source
      ..failReports = true
      ..failCrews = true;
    await tester.tap(find.byTooltip('Actualizar reportes'));
    await tester.pumpAndSettle();
    expect(find.text('#REP-1024'), findsOneWidget);
    expect(find.textContaining('No se pudieron actualizar los reportes. Se muestran los datos de la última carga exitosa.'), findsOneWidget);
    expect(find.textContaining('No se pudieron actualizar los equipos.'), findsOneWidget);

    source
      ..failReports = false
      ..failCrews = false
      ..reports = [];
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(retry, findsNothing);
    expect(find.text('#REP-1024'), findsNothing);
    expect(find.text('0 incidencias cargadas'), findsOneWidget);
    expect(find.textContaining('No hay reportes'), findsOneWidget);
  });

  testWidgets('Renderiza AdminReportsScreen con listado de incidencias y chips de filtro',
      (tester) async {
    final mockRepo = MockAdminRepository()
      ..reports = List.from(testReports)
      ..crews = List.from(testCrews);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminReportsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Título y subtítulo
    expect(find.text('Gestión de Reportes'), findsOneWidget);
    expect(find.textContaining('incidencias cargadas'), findsOneWidget);

    // 2. Buscador
    expect(find.byType(TextField), findsOneWidget);

    // 3. Filtros
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('Asignados'), findsOneWidget);

    // 4. Tarjetas de incidencias
    expect(find.text('#REP-1024'), findsOneWidget);
    expect(find.text('Acumulación de basura'), findsOneWidget);
    expect(find.text('Av. Abancay 450'), findsNothing);
    expect(find.text('Asignar Personal'), findsNothing);

    expect(find.text('#REP-2058'), findsOneWidget);
    expect(find.text('Contenedor lleno'), findsOneWidget);
    expect(find.text('Jr. de la Unión 810'), findsNothing);
    expect(find.textContaining('Hace '), findsNWidgets(2));
    expect(find.text('Reasignar Personal'), findsNothing);
    expect(find.text('Reportado por María Mendoza'), findsNothing);
  });

  testWidgets('Configura y confirma el despacho en una pantalla estrecha', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 600);
    addTearDown(tester.view.reset);
    final mockRepo = MockAdminRepository()
      ..reports = List.from(testReports)
      ..crews = List.from(testCrews);

    mockRepo.staff = [
      UserEntity(
        id: 'member',
        name: 'Integrante del equipo',
        email: 'miembro@example.com',
        teamId: testCrews.last.id,
        role: UserRole.staff,
        createdAt: DateTime(2025),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminReportsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Asignar Personal'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('#REP-1024'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('#REP-1024'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del reporte'), findsOneWidget);
    expect(find.text('Reportado por'), findsOneWidget);
    expect(find.text('María Mendoza'), findsOneWidget);
    expect(find.text('Apoyos de la comunidad'), findsOneWidget);
    expect(find.text('0 apoyos'), findsOneWidget);
    final dispatchButton = find.text('Asignar Personal');
    await tester.tap(dispatchButton);
    await tester.pumpAndSettle();

    expect(find.text('Asignar Personal').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Equipos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(testCrews.last.name));
    await tester.pumpAndSettle();
    expect(find.text('Instrucciones (opcional)'), findsNothing);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton<bool>), findsNothing);
    expect(find.byType(DropdownButtonFormField<ReportPriority>), findsNothing);
    expect(find.text(testCrews.last.name), findsOneWidget);
    expect(mockRepo.assignCalled, isFalse);
    final instructions = find.widgetWithText(TextField, 'Instrucciones (opcional)');
    await tester.ensureVisible(instructions);
    await tester.pumpAndSettle();
    await tester.enterText(instructions, ' Llevar pala ');
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton<bool>), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(instructions).controller?.text, ' Llevar pala ');
    final confirm = find.text('Confirmar asignación');
    expect(confirm.hitTestable(), findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(mockRepo.assignCalled, isTrue);
    expect(mockRepo.reports.first.assignedToTeamId, testCrews.last.id);
    expect(mockRepo.reports.first.priority, testReports.first.priority);
    expect(mockRepo.lastInstructions, 'Llevar pala');
    expect(find.text('Reasignar Personal'), findsOneWidget);
  });

  testWidgets('Asigna varias personas sin incluir integrantes de equipos ni personal ocupado', (tester) async {
    final repo = MockAdminRepository()
      ..reports = [testReports.first]
      ..busyStaffIds = {'busy'}
      ..staff = [
        for (final (id, name, team) in [
          ('rosa', 'Rosa Silva', null),
          ('luis', 'Luis Ruiz', null),
          ('busy', 'Ana Ocupada', null),
          ('member', 'Juan de Equipo', 'crew-01'),
        ])
          UserEntity(id: id, name: name, email: '$id@example.com', teamId: team,
            role: UserRole.staff, createdAt: DateTime(2025)),
      ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
        adminRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: AdminReportsScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#REP-1024'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asignar Personal'));
    await tester.pumpAndSettle();
    expect(find.text('Juan de Equipo'), findsNothing);
    expect(find.text('Con reporte activo'), findsOneWidget);
    await tester.tap(find.text('Ana Ocupada'));
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continuar')).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'rosa');
    await tester.pumpAndSettle();
    expect(find.text('Luis Ruiz'), findsNothing);
    await tester.tap(find.text('Rosa Silva'));
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luis Ruiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Rosa Silva, Luis Ruiz'), findsOneWidget);
    await tester.tap(find.text('Confirmar asignación'));
    await tester.pumpAndSettle();
    expect(repo.selectedStaffIds, ['rosa', 'luis']);
  });

  testWidgets('Carga otra página bajo demanda y permite reintentar sin perder el filtro', (tester) async {
    final repository = MockAdminRepository()
      ..reports = [testReports.first]
      ..nextReports = testReports
      ..crews = List.of(testCrews)
      ..firstCursor = _TestReportCursor()
      ..failNextPage = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AdminReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.nextPageRequests, 0);
    expect(find.text('#REP-1024'), findsOneWidget);
    expect(find.text('#REP-2058'), findsNothing);

    await tester.tap(find.text('Asignados'));
    await tester.pumpAndSettle();
    expect(find.text('#REP-1024'), findsNothing);
    await tester.tap(find.text('Cargar más reportes'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo cargar la página siguiente.'), findsOneWidget);

    repository.failNextPage = false;
    await tester.tap(find.text('Cargar más reportes'));
    await tester.pumpAndSettle();
    expect(repository.nextPageRequests, 2);
    expect(find.text('#REP-2058'), findsOneWidget);
    expect(find.text('Cargar más reportes'), findsNothing);
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    expect(find.text('#REP-1024'), findsOneWidget);
    expect(find.text('#REP-2058'), findsOneWidget);
  });

  testWidgets('Carga la página siguiente al llegar al final de la bandeja', (tester) async {
    final firstPage = List.generate(
      AdminReportPage.pageSize,
      (index) => testReports.first.copyWith(id: 'page-one-$index'),
    );
    final repository = MockAdminRepository()
      ..reports = firstPage
      ..nextReports = [testReports.last]
      ..firstCursor = _TestReportCursor();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: AdminReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('30 de 31 incidencias cargadas'), findsOneWidget);
    expect(repository.nextPageRequests, 0);

    final scroll = tester.widget<CustomScrollView>(find.byType(CustomScrollView)).controller!;
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(repository.nextPageRequests, 1);
    expect(find.text('Cargar más reportes'), findsNothing);
  });

  testWidgets('La vista de zona admite la opción de reportes abiertos ausente', (
    tester,
  ) async {
    final pending = testReports.first.copyWith(
      id: 'zone-pending',
      reportNumber: '#ACTIVO',
      status: ReportStatus.pending,
    );
    final resolved = pending.copyWith(
      id: 'zone-resolved',
      reportNumber: '#CERRADO',
      status: ReportStatus.resolved,
    );
    final container = ProviderContainer.test(
      overrides: [
        urbanReportsProvider.overrideWith(
          (_) async => {CajamarcaZone.central: [pending, resolved]},
        ),
      ],
    );

    Future<void> showZone(bool? openOnly) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AdminReportsScreen(
              zone: CajamarcaZone.central,
              openOnly: openOnly,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await showZone(true);
    expect(find.text('#ACTIVO'), findsOneWidget);
    expect(find.text('#CERRADO'), findsNothing);
    expect(find.text('Resueltos'), findsNothing);

    await showZone(null);
    expect(find.text('#ACTIVO'), findsOneWidget);
    expect(find.text('#CERRADO'), findsOneWidget);
    expect(find.text('Resueltos'), findsOneWidget);
  });

  testWidgets('Muestra por páginas los resultados del filtro de zona', (tester) async {
    final reports = List.generate(
      35,
      (index) => testReports.first.copyWith(id: 'central-$index'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(MockAdminRepository()),
          urbanReportsProvider.overrideWith((_) async => {CajamarcaZone.central: reports}),
        ],
        child: const MaterialApp(home: AdminReportsScreen(zone: CajamarcaZone.central)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('30 de 35 incidencias cargadas'), findsOneWidget);
    final scroll = tester.widget<CustomScrollView>(find.byType(CustomScrollView)).controller!;
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('35 incidencias cargadas'), findsOneWidget);
  });
}
