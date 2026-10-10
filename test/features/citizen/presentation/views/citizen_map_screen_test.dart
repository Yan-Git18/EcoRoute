import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/services/location_service.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_category_entity.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/citizen/domain/repositories/report_repository.dart';
import 'package:ecoroute/features/citizen/presentation/viewmodels/create_report_viewmodel.dart';
import 'package:ecoroute/features/citizen/presentation/views/citizen_map_screen.dart';

class MockLocationService implements LocationService {
  @override
  Future<LocationDataResult> getCurrentPosition() async {
    return const LocationDataResult(
      latitude: -12.046374,
      longitude: -77.042793,
      address: 'Plaza Mayor de Lima',
    );
  }

  @override
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    return 'Plaza Mayor de Lima';
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
    return Success(reports.first);
  }

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async {
    return Success(reports);
  }
}

void main() {
  late MockReportRepository mockRepo;
  late MockLocationService mockLocationService;

  final testReports = [
    ReportEntity(
      id: 'rep-1',
      reportNumber: '#REP-1024',
      citizenId: 'c-1',
      citizenName: 'Carlos',
      categoryId: 'waste_accumulation',
      categoryName: 'Acumulación de basura',
      categoryIcon: 'delete_outline_rounded',
      description: 'Montículo en la esquina',
      priority: ReportPriority.high,
      status: ReportStatus.pending,
      latitude: -12.0478,
      longitude: -77.0415,
      address: 'Av. Abancay 450',
      imageUrls: const [],
      createdAt: DateTime.now(),
    ),
    ReportEntity(
      id: 'rep-2',
      reportNumber: '#REP-2058',
      citizenId: 'c-2',
      citizenName: 'Ana',
      categoryId: 'full_bin',
      categoryName: 'Contenedor lleno',
      categoryIcon: 'delete_sweep_rounded',
      description: 'Tacho saturado',
      priority: ReportPriority.medium,
      status: ReportStatus.inProgress,
      latitude: -12.0452,
      longitude: -77.0435,
      address: 'Jr. de la Unión 810',
      imageUrls: const [],
      createdAt: DateTime.now(),
    ),
  ];

  setUp(() {
    mockRepo = MockReportRepository();
    mockRepo.reports = testReports;
    mockLocationService = MockLocationService();
  });

  testWidgets('Renderiza CitizenMapScreen en Vista 9 (Mapa) con buscador, filtros y leyenda',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(mockRepo),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
        child: const MaterialApp(
          home: CitizenMapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Selector de modo de vista presente con "Mapa" y "Cercanos"
    expect(find.text('Mapa'), findsWidgets);
    expect(find.text('Cercanos'), findsOneWidget);

    // 2. Buscador y chips de filtro presentes
    expect(find.text('Buscar por dirección o tipo de residuo...'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('En proceso'), findsWidgets);
    expect(find.text('Resueltos'), findsOneWidget);

    // 3. Leyenda flotante de estados presente
    expect(find.text('Leyenda'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);

    // 4. Botón flotante de GPS presente
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
  });

  testWidgets('Alterna de Vista Mapa a Vista 10 (Reportes Cercanos en Lista) con tarjetas y badges',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(mockRepo),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
        child: const MaterialApp(
          home: CitizenMapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pulsamos en el botón "Cercanos"
    await tester.tap(find.text('Cercanos'));
    await tester.pumpAndSettle();

    // Verificamos el resumen de incidencias ordenadas por proximidad
    expect(find.textContaining('incidencias ordenadas por proximidad'), findsOneWidget);

    // Verificamos que se renderizan las tarjetas de reportes cercanos con su número y badges
    expect(find.text('#REP-1024'), findsOneWidget);
    expect(find.text('Acumulación de basura'), findsOneWidget);
    expect(find.text('Av. Abancay 450'), findsOneWidget);
    expect(find.text('Prioridad Alta'), findsOneWidget);

    expect(find.text('#REP-2058'), findsOneWidget);
    expect(find.text('Contenedor lleno'), findsOneWidget);
    expect(find.text('Jr. de la Unión 810'), findsOneWidget);
    expect(find.text('Prioridad Media'), findsOneWidget);
  });

  testWidgets('Filtra por estado en la vista de Reportes Cercanos',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(mockRepo),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
        child: const MaterialApp(
          home: CitizenMapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Cambiamos a Vista Cercanos
    await tester.tap(find.text('Cercanos'));
    await tester.pumpAndSettle();

    // Filtramos solo por 'Pendientes'
    await tester.tap(find.text('Pendientes'));
    await tester.pumpAndSettle();

    // Solo debe aparecer el reporte pendiente (#REP-1024)
    expect(find.text('#REP-1024'), findsOneWidget);
    expect(find.text('#REP-2058'), findsNothing);
  });
}
