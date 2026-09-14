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
import 'package:ecoroute/features/citizen/presentation/views/my_reports_screen.dart';

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
}

final testCitizen = UserEntity(
  id: 'c-1',
  name: 'Juan Pérez',
  email: 'juan@ecoroute.com',
  role: UserRole.citizen,
  createdAt: DateTime.now(),
);

void main() {
  testWidgets('Muestra estado vacío sin datos falsos cuando el usuario no tiene reportes', (WidgetTester tester) async {
    final mockRepo = MockReportRepository();
    mockRepo.reports = [];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAuthViewModel(testCitizen)),
          reportRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: MyReportsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verificamos encabezado
    expect(find.text('Mis reportes'), findsWidgets);

    // 2. Verificamos los filtros superiores
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('En proceso'), findsOneWidget);
    expect(find.text('Resueltos'), findsOneWidget);

    // 3. Verificamos que se muestre el estado vacío y NO datos falsos
    expect(find.text('No tienes reportes aún'), findsOneWidget);
    expect(find.text('Crear mi primer reporte'), findsOneWidget);
  });

  testWidgets('Muestra tarjetas de reportes cuando el usuario tiene reportes registrados', (WidgetTester tester) async {
    final mockRepo = MockReportRepository();
    mockRepo.reports = [
      ReportEntity(
        id: 'rep-01',
        reportNumber: '#0012',
        citizenId: 'c-1',
        citizenName: 'Juan Pérez',
        categoryId: 'waste_accumulation',
        categoryName: 'Acumulación de basura',
        categoryIcon: 'delete_outline_rounded',
        description: 'Bolsas acumuladas.',
        priority: ReportPriority.high,
        status: ReportStatus.inProgress,
        latitude: -12.046,
        longitude: -77.042,
        address: 'Av. Los Incas, Cajamarca',
        imageUrls: const [],
        createdAt: DateTime(2025, 9, 12, 10, 24),
      ),
      ReportEntity(
        id: 'rep-02',
        reportNumber: '#0008',
        citizenId: 'c-1',
        citizenName: 'Juan Pérez',
        categoryId: 'waste_public_road',
        categoryName: 'Residuos en vía pública',
        categoryIcon: 'cleaning_services_rounded',
        description: 'Basura en vereda.',
        priority: ReportPriority.low,
        status: ReportStatus.resolved,
        latitude: -12.046,
        longitude: -77.042,
        address: 'Av. Perú 500',
        imageUrls: const [],
        createdAt: DateTime(2025, 9, 5, 14, 0),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockAuthViewModel(testCitizen)),
          reportRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: MyReportsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verificamos que se muestren ambos reportes
    expect(find.text('#0012'), findsOneWidget);
    expect(find.text('Acumulación de basura'), findsOneWidget);
    expect(find.text('Av. Los Incas, Cajamarca'), findsOneWidget);

    expect(find.text('#0008'), findsOneWidget);
    expect(find.text('Residuos en vía pública'), findsOneWidget);

    // 2. Filtramos por 'Resueltos'
    await tester.tap(find.text('Resueltos'));
    await tester.pumpAndSettle();

    expect(find.text('#0008'), findsOneWidget);
    expect(find.text('#0012'), findsNothing);
  });
}
