import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/result.dart';
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

class MockAdminMapRepository implements AdminRepository {
  List<ReportEntity> reports = [];
  List<MunicipalCrewEntity> crews = [];

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async => Success(reports);

  @override
  Future<Result<List<MunicipalCrewEntity>>> getAvailableCrews() async => Success(crews);

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
    latitude: -12.0460,
    longitude: -77.0420,
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
    latitude: -12.0470,
    longitude: -77.0430,
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
    latitude: -12.0465,
    longitude: -77.0425,
  ),
];

void main() {
  testWidgets('Renderiza AdminLiveMapScreen con filtros de capa y barra inferior', (tester) async {
    final mockRepo = MockAdminMapRepository()
      ..reports = List.from(testMapReports)
      ..crews = List.from(testMapCrews);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminLiveMapScreen(),
        ),
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
    expect(find.text('Cuadrillas (1)'), findsOneWidget);

    // 3. Menú inferior con tab activo
    expect(find.byType(AdminBottomNavBar), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Reportes'), findsOneWidget);
    expect(find.text('Cuadrillas'), findsOneWidget);
  });

  testWidgets('Permite alternar filtros y seleccionar reporte para ver tarjeta emergente',
      (tester) async {
    final mockRepo = MockAdminMapRepository()
      ..reports = List.from(testMapReports)
      ..crews = List.from(testMapCrews);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminLiveMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Simular selección de reporte en el mapa de prueba
    final selectReportBtn = find.text('Simular Selección de Reporte');
    expect(selectReportBtn, findsOneWidget);
    await tester.tap(selectReportBtn);
    await tester.pumpAndSettle();

    // Verificar que se abre la tarjeta de vista previa
    expect(find.byType(AdminMapReportPreviewCard), findsOneWidget);
    expect(find.text('#REP-0101'), findsOneWidget);
    expect(find.text('Acumulación de basura'), findsOneWidget);
    expect(find.text('Jr. Carabaya 450'), findsOneWidget);
    expect(find.text('Despachar'), findsOneWidget);

    // Cerrar la tarjeta de vista previa
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(AdminMapReportPreviewCard), findsNothing);
  });

  testWidgets('Permite seleccionar cuadrilla para ver tarjeta de operario y camión',
      (tester) async {
    final mockRepo = MockAdminMapRepository()
      ..reports = List.from(testMapReports)
      ..crews = List.from(testMapCrews);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminLiveMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Simular selección de cuadrilla
    final selectCrewBtn = find.text('Simular Selección de Cuadrilla');
    expect(selectCrewBtn, findsOneWidget);
    await tester.tap(selectCrewBtn);
    await tester.pumpAndSettle();

    // Verificar tarjeta de cuadrilla
    expect(find.byType(AdminMapCrewPreviewCard), findsOneWidget);
    expect(find.text('Cuadrilla Centro Histórico'), findsOneWidget);
    expect(find.textContaining('Camión #01'), findsOneWidget);
    expect(find.textContaining('ECR-119'), findsOneWidget);
    expect(find.text('Ver Reportes Asignados'), findsOneWidget);
  });
}
