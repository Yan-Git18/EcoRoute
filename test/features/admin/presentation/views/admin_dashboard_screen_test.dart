import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/admin/domain/entities/municipal_crew_entity.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_viewmodel.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_dashboard_screen.dart';
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
  testWidgets('Renderiza AdminDashboardScreen con métricas vivas y módulos de gestión',
      (tester) async {
    final mockRepo = MockAdminRepository()..reports = List.from(testReports);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAdminAuthViewModel(testAdminUser)),
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Título y Banner
    expect(find.text('Administración Municipal'), findsOneWidget);
    expect(find.text('Ing. Marco Municipal'), findsOneWidget);
    expect(find.text('Gestión de Residuos Urbanos • EcoRoute'), findsOneWidget);

    // 2. Resumen de Métricas
    expect(find.text('Resumen Municipal de Reportes'), findsOneWidget);
    expect(find.text('Total Reportes'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('Resueltos'), findsOneWidget);

    // 3. Módulos de Gestión
    expect(find.text('Módulos de Gestión'), findsOneWidget);
    expect(find.text('Gestión y Asignación de Reportes'), findsOneWidget);
    expect(find.text('Monitoreo en Mapa en Tiempo Real'), findsOneWidget);
    expect(find.text('Gestión de Personal y Flota'), findsOneWidget);

    // 4. Incidencia urgente destacada
    expect(find.text('Incidencias Pendientes Urgentes'), findsOneWidget);
    expect(find.text('Av. Grau 120'), findsOneWidget);
    expect(find.text('Atender'), findsOneWidget);

    // 5. Menú de navegación inferior (AdminBottomNavBar)
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Reportes'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
  });
}
