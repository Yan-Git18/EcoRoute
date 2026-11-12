import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/admin/domain/entities/municipal_crew_entity.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_viewmodel.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_fleet_screen.dart';
import 'package:ecoroute/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';

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
  Future<Result<List<ReportEntity>>> getAllReports() async => const Success([]);

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

final testFleetAdminUser = UserEntity(
  id: 'admin-1',
  name: 'Ing. Supervisor',
  email: 'admin@ecoroute.com',
  role: UserRole.admin,
  createdAt: DateTime(2025, 1, 1),
);

final testFleetVehicles = [
  const MunicipalCrewEntity(
    id: 'crew-1',
    name: 'Cuadrilla Zona Norte',
    zone: 'Sector 1 (Los Próceres)',
    leadStaffName: 'Mario Choque',
    vehicleCode: 'Camión #04',
    vehiclePlate: 'ECR-882',
    vehicleType: 'Camión Compactador 15m³',
    status: MunicipalCrewStatus.onRoute,
  ),
  const MunicipalCrewEntity(
    id: 'crew-2',
    name: 'Cuadrilla Centro',
    zone: 'Sector Central',
    leadStaffName: 'Rosa Flores',
    vehicleCode: 'Camión #01',
    vehiclePlate: 'ECR-119',
    vehicleType: 'Furgón Barrendero Ligero',
    status: MunicipalCrewStatus.available,
  ),
  const MunicipalCrewEntity(
    id: 'crew-3',
    name: 'Cuadrilla Especial',
    zone: 'Sector Sur',
    leadStaffName: 'Jorge Mantenimiento',
    vehicleCode: 'Camión #05',
    vehiclePlate: 'ECR-554',
    vehicleType: 'Camión Volquete Pesado',
    status: MunicipalCrewStatus.maintenance,
  ),
];

void main() {
  testWidgets('Renderiza AdminFleetScreen con métricas de flota, matrículas y estados mecánicos', (tester) async {
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

    // 1. Título y encabezado
    expect(find.text('Flota y Maquinaria Municipal'), findsOneWidget);
    expect(find.textContaining('unidades • 1 en mantenimiento'), findsOneWidget);

    // 2. Métricas de flota
    expect(find.text('Total Flota'), findsOneWidget);
    expect(find.text('En Circuito'), findsWidgets);
    expect(find.text('En Base'), findsWidgets);
    expect(find.text('En Taller'), findsWidgets);

    // 3. Tarjetas de vehículos y matrículas
    expect(find.text('Camión #04'), findsOneWidget);
    expect(find.text('ECR-882'), findsOneWidget);
    expect(find.text('Camión Compactador 15m³'), findsOneWidget);

    expect(find.text('Camión #01'), findsOneWidget);
    expect(find.text('ECR-119'), findsOneWidget);

    expect(find.text('Camión #05'), findsOneWidget);
    expect(find.text('ECR-554'), findsOneWidget);

    // 4. Barra de navegación
    expect(find.byType(AdminBottomNavBar), findsOneWidget);
    expect(find.text('Cuadrillas'), findsOneWidget);
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

    // Buscar botón 'Enviar a Taller' en el primer camión operativo
    final sendToWorkshopButtons = find.text('Enviar a Taller');
    expect(sendToWorkshopButtons, findsWidgets);

    await tester.tap(sendToWorkshopButtons.first);
    await tester.pumpAndSettle();

    expect(mockRepo.updateCrewCalled, isTrue);
  });
}

