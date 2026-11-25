import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/admin/domain/entities/admin_report_page.dart';
import 'package:ecoroute/features/admin/domain/entities/municipal_crew_entity.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_viewmodel.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_fleet_screen.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';

import '../../admin_report_fixtures.dart';

class MockAdminFleetAuthViewModel extends AuthViewModel {
  final UserEntity? testUser;
  MockAdminFleetAuthViewModel(this.testUser);

  @override
  AuthState build() {
    return AuthState(user: testUser, isInitialized: true);
  }
}

class MockAdminFleetRepository implements AdminRepository {
  List<MunicipalCrewEntity> crews = [];
  bool updateCrewCalled = false;

  @override
  Future<Result<AdminReportPage<ReportEntity>>> getReportsPage({AdminReportCursor? after}) async =>
      const Success(AdminReportPage([]));

  @override
  Future<Result<AdminReportTotals>> getReportTotals() async => Success(totalsForReports(const []));

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
    updateCrewCalled = true;
    final index = crews.indexWhere((c) => c.id == crew.id);
    if (index >= 0) {
      crews[index] = crew;
    }
    return Success(crew);
  }

  @override
  Future<Result<void>> deleteVehicle(String vehicleId) async {
    crews.removeWhere((crew) => crew.vehicleOnly && crew.id == vehicleId);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteCrew(String crewId) async {
    crews.removeWhere((c) => c.id == crewId);
    return const Success(null);
  }

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
  Future<Result<UserEntity?>> searchUserByExactEmail(String email) async => const Success(null);

  @override
  Future<Result<void>> updateUserRole({
    required String userId,
    required UserRole newRole,
    String? teamId,
  }) async => const Success(null);
}

final testFleetAdminUser = UserEntity(
  id: 'admin-1',
  name: 'Ing. Supervisor',
  email: 'admin@ecoroute.com',
  role: UserRole.admin,
  createdAt: DateTime(2025, 1, 1),
);

final testFleetVehicles = [
  const MunicipalCrewEntity(
    id: 'truck-1',
    name: 'Camión #04',
    zone: 'Sector 1 (Los Próceres)',
    leadStaffName: 'Mario Choque',
    vehicleCode: 'Camión #04',
    vehiclePlate: 'ECR-882',
    vehicleType: 'Camión Compactador 15m³',
    vehicleOnly: true,
    assignedCrewId: 'crew-1',
  ),
  const MunicipalCrewEntity(
    id: 'truck-2',
    name: 'Cuadrilla Centro',
    zone: 'Sector Central',
    leadStaffName: 'Rosa Flores',
    vehicleCode: 'Camión #01',
    vehiclePlate: 'ECR-119',
    vehicleType: 'Furgón Barrendero Ligero',
    status: MunicipalCrewStatus.available,
    vehicleOnly: true,
  ),
  const MunicipalCrewEntity(
    id: 'truck-3',
    name: 'Cuadrilla Especial',
    zone: 'Sector Sur',
    leadStaffName: 'Jorge Mantenimiento',
    vehicleCode: 'Camión #05',
    vehiclePlate: 'ECR-554',
    vehicleType: 'Camión Volquete Pesado',
    status: MunicipalCrewStatus.maintenance,
    vehicleOnly: true,
  ),
  const MunicipalCrewEntity(
    id: 'crew-1',
    name: 'Cuadrilla Zona Norte',
    zone: 'Sector 1',
    leadStaffName: 'Mario Choque',
    leaderId: 'staff-1',
    vehicleCode: 'Camión #04',
    vehiclePlate: 'ECR-882',
    vehicleId: 'truck-1',
    activeTasksCount: 1,
    status: MunicipalCrewStatus.onRoute,
  ),
];

void main() {
  testWidgets('Muestra filas compactas y obtiene el conductor del equipo en el detalle', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = MockAdminFleetRepository()..crews = List.from(testFleetVehicles);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminFleetAuthViewModel(testFleetAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminFleetScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Flota Vehicular'), findsOneWidget);
    expect(find.text('Total Flota'), findsNothing);
    expect(find.text('Enviar al taller'), findsNothing);
    expect(find.text('Mario Choque'), findsNothing);
    expect(find.text('Camión #04'), findsOneWidget);
    expect(find.text('ECR-882'), findsOneWidget);
    expect(find.text('Camión Compactador 15m³'), findsNothing);

    expect(find.text('Camión #01'), findsOneWidget);
    expect(find.text('ECR-119'), findsOneWidget);

    expect(find.text('Camión #05'), findsOneWidget);
    expect(find.text('ECR-554'), findsOneWidget);

    expect(find.byType(AdminBottomNavBar), findsOneWidget);
    expect(find.text('Equipo'), findsOneWidget);

    await tester.tap(find.text('Camión #04'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del vehículo'), findsOneWidget);
    expect(find.text('Camión Compactador 15m³'), findsOneWidget);
    expect(find.text('Mario Choque'), findsOneWidget);
    expect(find.text('Cuadrilla Zona Norte'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.text('Detalle del vehículo')),
    );
    mockRepo.crews[3] = mockRepo.crews[3].copyWith(leadStaffName: 'Rosa Flores', leaderId: 'staff-2');
    await container.read(adminReportsViewModelProvider.notifier).refresh();
    await tester.pumpAndSettle();
    expect(find.text('Rosa Flores'), findsOneWidget);
    expect(find.text('Mario Choque'), findsNothing);
    expect(
      tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Enviar al taller'), matching: find.bySubtype<OutlinedButton>()),
      ).onPressed,
      isNull,
    );
    expect(
      tester.widget<TextButton>(
        find.ancestor(of: find.text('Eliminar vehículo'), matching: find.bySubtype<TextButton>()),
      ).onPressed,
      isNull,
    );
  });

  testWidgets('Filtra vehículos al escribir en el buscador de placa o conductor', (tester) async {
    final mockRepo = MockAdminFleetRepository()..crews = List.from(testFleetVehicles);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminFleetAuthViewModel(testFleetAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminFleetScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Escribir en el buscador la placa ECR-119
    final searchInput = find.byType(TextField);
    await tester.enterText(searchInput, 'ECR-119');
    await tester.pumpAndSettle();

    expect(find.text('Camión #01'), findsOneWidget);
    expect(find.text('Camión #04'), findsNothing);
  });

  testWidgets('Permite alternar estado mecánico de camión a Taller Mecánico', (tester) async {
    final mockRepo = MockAdminFleetRepository()..crews = List.from(testFleetVehicles);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminFleetAuthViewModel(testFleetAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminFleetScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Camión #01'));
    await tester.pumpAndSettle();
    expect(find.text('No asignado'), findsOneWidget);
    expect(find.text('Rosa Flores'), findsNothing);
    await tester.tap(find.text('Enviar al taller'));
    await tester.pumpAndSettle();

    expect(mockRepo.updateCrewCalled, isTrue);
    expect(find.text('Registrar salida del taller'), findsOneWidget);
    await tester.tap(find.text('Registrar salida del taller'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar al taller'), findsOneWidget);

    await tester.tap(find.text('Eliminar vehículo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del vehículo'), findsNothing);
    expect(find.text('Camión #01'), findsNothing);
  });

  testWidgets('Crea y edita vehículos con código, placa y tipo', (tester) async {
    final repo = MockAdminFleetRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(() => MockAdminFleetAuthViewModel(testFleetAdminUser)),
        adminRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: AdminFleetScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo vehículo'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Nombre o código del vehículo'), findsOneWidget);
    expect(find.text('Conductor'), findsNothing);
    expect(find.text('Sector Habitual'), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, 'Camión 08');
    await tester.enterText(find.byType(TextFormField).last, 'ecr-080');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camión Recolector Urbano').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear vehículo'));
    await tester.pumpAndSettle();
    expect(repo.crews.single.leadStaffName, 'No asignado');
    expect(repo.crews.single.vehiclePlate, 'ECR-080');
    await tester.tap(find.text('Camión 08'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar vehículo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'ECR-081');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(find.text('ECR-081'), findsOneWidget);
  });
}

