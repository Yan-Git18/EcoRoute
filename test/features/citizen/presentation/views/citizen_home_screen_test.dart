import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_category_entity.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/citizen/domain/repositories/report_repository.dart';
import 'package:ecoroute/features/citizen/presentation/viewmodels/create_report_viewmodel.dart';
import 'package:ecoroute/features/citizen/presentation/views/citizen_home_screen.dart';

class MockAuthViewModel extends AuthViewModel {
  final UserEntity? testUser;
  MockAuthViewModel(this.testUser);

  @override
  AuthState build() {
    return AuthState(
      user: testUser,
      isInitialized: true,
    );
  }
}

class MockReportRepository implements ReportRepository {
  List<ReportEntity> reports = [];

  @override
  Future<Result<List<ReportCategoryEntity>>> getCategories() async {
    return const Success(ReportCategoryEntity.defaultCategories);
  }

  @override
  Future<Result<ReportEntity>> createReport({
    required ReportEntity report,
    List<int>? imageBytes,
    String? imageFileName,
    List<List<int>>? multipleImageBytes,
    List<String>? localImagePaths,
  }) async {
    return Success(report);
  }

  @override
  Future<Result<List<ReportEntity>>> getMyReports(String citizenId) async {
    return Success(reports);
  }

  @override
  Future<Result<ReportEntity>> getReportById(String reportId) async {
    final match = reports.firstWhere((r) => r.id == reportId);
    return Success(match);
  }

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async {
    return Success(reports);
  }

  @override
  Future<Result<ReportEntity>> cancelReport({required String reportId, String? reason}) async {
    final match = reports.firstWhere((r) => r.id == reportId);
    return Success(match.copyWith(status: ReportStatus.cancelled));
  }
}

final testCarlosUser = UserEntity(
  id: 'c-100',
  name: 'Carlos Mendoza',
  email: 'carlos@ecoroute.com',
  role: UserRole.citizen,
  createdAt: DateTime(2025, 1, 1),
);

void main() {
  testWidgets('Renderiza CitizenHomeScreen con diseño de EcoRoute coincidente con el mockup',
      (tester) async {
    final mockRepo = MockReportRepository();
    mockRepo.reports = [
      ReportEntity(
        id: 'rep-1',
        reportNumber: '#0001',
        citizenId: 'c-100',
        citizenName: 'Carlos Mendoza',
        categoryId: 'waste_accumulation',
        categoryName: 'Acumulación de basura',
        categoryIcon: 'delete_outline_rounded',
        description: 'Bolsas de residuos en la esquina',
        address: 'Av. Las Palmas 123',
        status: ReportStatus.pending,
        priority: ReportPriority.medium,
        latitude: -12.046,
        longitude: -77.042,
        imageUrls: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAuthViewModel(testCarlosUser)),
          reportRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: CitizenHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Marca y AppBar
    expect(find.text('EcoRoute'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // 2. Saludo personalizado
    expect(find.text('¡Hola, Carlos!'), findsOneWidget);
    expect(
      find.text('Tu reporte ayuda a mantener una ciudad más limpia y saludable.'),
      findsOneWidget,
    );

    // 3. Tarjeta Hero "Reportar problema"
    expect(find.text('Reportar problema'), findsOneWidget);
    expect(
      find.text('Toma una foto y envía tu reporte en pocos pasos.'),
      findsOneWidget,
    );

    // 4. Sección "Mis reportes" y contadores
    expect(find.text('Mis reportes'), findsWidgets);
    expect(find.text('Ver todos'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('En proceso'), findsOneWidget);
    expect(find.text('Resueltos'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // 1 pendiente

    // 5. Acciones rápidas
    expect(find.text('Acciones rápidas'), findsOneWidget);
    expect(find.text('Mapa'), findsWidgets);
    expect(find.text('Ver incidencias\ncercanas'), findsOneWidget);

    // 6. Barra de navegación inferior
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Reportar'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });
}
