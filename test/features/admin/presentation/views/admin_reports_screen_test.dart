import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/errors/failures.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/admin/domain/entities/municipal_crew_entity.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_viewmodel.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_reports_screen.dart';
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

class MockAdminRepository implements AdminRepository {
  List<ReportEntity> reports = [];
  List<MunicipalCrewEntity> crews = [];
  bool assignCalled = false;

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async {
    return Success(reports);
  }

  @override
  Future<Result<List<MunicipalCrewEntity>>> getAvailableCrews() async {
    return Success(crews);
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
    final index = reports.indexWhere((r) => r.id == reportId);
    if (index >= 0) {
      final updated = reports[index].copyWith(
        status: ReportStatus.assigned,
        assignedToTeamId: crew.id,
        assignedToTeamName: crew.name,
        assignedStaffName: crew.leadStaffName,
        assignedVehicle: '${crew.vehicleCode} • ${crew.vehiclePlate}',
      );
      reports[index] = updated;
      return Success(updated);
    }
    return FailureResult(ServerFailure(message: 'No encontrado'));
  }

  @override
  Future<Result<ReportEntity>> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  }) async {
    throw UnimplementedError();
  }
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
    vehicleCode: 'Camión #02',
    vehiclePlate: 'ECR-341',
    activeTasksCount: 0,
  ),
];

void main() {
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
    expect(find.textContaining('incidencias en supervisión'), findsOneWidget);

    // 2. Buscador
    expect(find.byType(TextField), findsOneWidget);

    // 3. Filtros
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('Asignados'), findsOneWidget);

    // 4. Tarjetas de incidencias
    expect(find.text('#REP-1024'), findsOneWidget);
    expect(find.text('Acumulación de basura'), findsOneWidget);
    expect(find.text('Av. Abancay 450'), findsOneWidget);
    expect(find.text('Despachar Cuadrilla'), findsOneWidget);

    expect(find.text('#REP-2058'), findsOneWidget);
    expect(find.text('Contenedor lleno'), findsOneWidget);
    expect(find.text('Jr. de la Unión 810'), findsOneWidget);
    expect(find.text('Reasignar Cuadrilla'), findsOneWidget);
  });

  testWidgets('Abre modal de despacho y asigna cuadrilla a un reporte pendiente', (tester) async {
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

    // Tap en Despachar Cuadrilla
    final dispatchButton = find.text('Despachar Cuadrilla');
    expect(dispatchButton, findsOneWidget);
    await tester.tap(dispatchButton);
    await tester.pumpAndSettle();

    // Debe abrir el modal
    expect(find.text('Despacho de Cuadrilla'), findsOneWidget);
    expect(find.text('Confirmar Despacho a Cuadrilla'), findsOneWidget);

    // Confirmar despacho
    await tester.tap(find.text('Confirmar Despacho a Cuadrilla'));
    await tester.pumpAndSettle();

    expect(mockRepo.assignCalled, isTrue);
  });
}
