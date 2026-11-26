import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/services/location_service.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_category_entity.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/citizen/domain/repositories/report_repository.dart';
import 'package:ecoroute/features/citizen/presentation/viewmodels/create_report_viewmodel.dart';
import 'package:ecoroute/features/citizen/presentation/views/citizen_map_screen.dart';
import 'package:ecoroute/features/citizen/presentation/widgets/citizen_map_preview_card.dart';
import 'package:ecoroute/features/citizen/presentation/widgets/citizen_map_view.dart';

class _CitizenSession extends AuthViewModel {
  @override
  AuthState build() => AuthState(
    isInitialized: true,
    user: UserEntity(
      id: 'c-1',
      name: 'Carlos',
      email: 'carlos@example.com',
      role: UserRole.citizen,
      createdAt: DateTime(2025),
    ),
  );
}

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

  @override
  Future<LocationDataResult?> getCoordinatesFromAddress(String address) async {
    return const LocationDataResult(
      latitude: -12.046374,
      longitude: -77.042793,
      address: 'Plaza Mayor de Lima',
    );
  }
}

class MockReportRepository implements ReportRepository {
  List<ReportEntity> reports = [];
  List<ReportEntity> ownReports = [];
  int mapLoads = 0;
  final ownReportQueries = <String>[];

  @override
  Future<Result<List<ReportCategoryEntity>>> getCategories() async {
    return const Success(ReportCategoryEntity.defaultCategories);
  }

  @override
  Future<Result<ReportEntity>> createReport({
    required ReportEntity report,
    List<int>? imageBytes,
    List<List<int>>? multipleImageBytes,
  }) async {
    return Success(report);
  }

  @override
  Future<Result<List<ReportEntity>>> getMyReports(String citizenId) async {
    ownReportQueries.add(citizenId);
    return Success(
      ownReports.where((report) => report.citizenId == citizenId).toList(),
    );
  }

  @override
  Future<Result<ReportEntity>> getReportById(String reportId) async {
    return Success(reports.first);
  }

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async {
    mapLoads++;
    return Success(reports);
  }

  @override
  Future<Result<ReportEntity>> cancelReport({
    required String reportId,
    String? reason,
  }) async {
    return Success(reports.first.copyWith(status: ReportStatus.cancelled));
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
      latitude: -7.1594,
      longitude: -78.5167,
      address: 'Av. Abancay 450',
      imageUrls: const [],
      createdAt: DateTime.now(),
    ),
    ReportEntity(
      id: 'rep-2',
      reportNumber: 'PR-RUTAS-1F30E5-85',
      citizenId: 'c-2',
      citizenName: 'Ana',
      categoryId: 'full_bin',
      categoryName: 'Contenedor lleno',
      categoryIcon: 'delete_sweep_rounded',
      description: 'Tacho saturado',
      priority: ReportPriority.medium,
      status: ReportStatus.inProgress,
      latitude: -7.1568,
      longitude: -78.5187,
      address: 'Jr. de la Unión 810',
      imageUrls: const [],
      createdAt: DateTime.now(),
    ),
  ];

  setUp(() {
    mockRepo = MockReportRepository();
    mockRepo.reports = testReports
        .map((report) => report.copyWith(citizenId: ''))
        .toList();
    mockRepo.ownReports = [
      ...testReports,
      testReports.first.copyWith(
        id: 'rep-older',
        status: ReportStatus.resolved,
        createdAt: DateTime(2025),
      ),
    ];
    mockLocationService = MockLocationService();
  });

  testWidgets(
    'Muestra el mapa con selector, buscador, filtros y leyenda',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(mockRepo),
            locationServiceProvider.overrideWithValue(mockLocationService),
          ],
          child: const MaterialApp(home: CitizenMapScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(mockRepo.mapLoads, 1);
      expect(
        find.text('Últimos 30 días · Hasta 100 reportes recientes'),
        findsOneWidget,
      );

      final appBar = find.byType(AppBar);
      expect(
        find.descendant(of: appBar, matching: find.text('Todos')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: appBar, matching: find.text('Mis reportes')),
        findsOneWidget,
      );

      // 2. Buscador y chips de filtro presentes
      expect(
        find.text('Buscar por dirección o tipo de residuo...'),
        findsOneWidget,
      );
      expect(find.text('Todos'), findsNWidgets(2));
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('En proceso'), findsWidgets);
      expect(find.text('Resueltos'), findsOneWidget);

      // 3. Leyenda flotante de estados presente
      expect(find.text('Leyenda'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);

      // 4. Botón flotante de GPS presente
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    },
  );

  testWidgets('Filtra los pines por ciudadano en el mismo mapa', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(_CitizenSession.new),
          reportRepositoryProvider.overrideWithValue(mockRepo),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
        child: const MaterialApp(home: CitizenMapScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final mapFinder = find.byType(CitizenMapView);
    final mapState = tester.state(mapFinder);
    List<String> visibleIds() => tester
        .widget<CitizenMapView>(mapFinder)
        .reports
        .map((report) => report.id)
        .toList();
    Finder topTab(String label) =>
        find.descendant(of: find.byType(AppBar), matching: find.text(label));

    expect(visibleIds(), ['rep-1', 'rep-2']);
    expect(mockRepo.ownReportQueries, isEmpty);

    await tester.tap(find.byIcon(Icons.location_on_rounded).last);
    await tester.pumpAndSettle();
    final preview = find.byType(CitizenMapPreviewCard);
    expect(tester.widget<CitizenMapPreviewCard>(preview).report.id, 'rep-2');

    await tester.tap(topTab('Mis reportes'));
    await tester.pumpAndSettle();

    expect(tester.state(mapFinder), same(mapState));
    expect(mockRepo.ownReportQueries, ['c-1']);
    expect(visibleIds(), ['rep-1', 'rep-older']);
    expect(preview, findsNothing);
    expect(find.textContaining('Últimos 30 días'), findsNothing);

    await tester.tap(find.text('Pendientes'));
    await tester.pumpAndSettle();
    expect(visibleIds(), ['rep-1']);

    await tester.enterText(find.byType(TextField), 'Jr. de la Unión');
    await tester.pumpAndSettle();
    expect(visibleIds(), isEmpty);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(topTab('Todos'));
    await tester.pumpAndSettle();
    expect(visibleIds(), ['rep-1']);
    expect(tester.state(mapFinder), same(mapState));
    expect(mockRepo.mapLoads, 1);
  });

  testWidgets(
    'La vista previa con folio largo cabe en una pantalla estrecha',
    (tester) async {
      tester.view.physicalSize = const Size(640, 1400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var closed = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: CitizenMapPreviewCard(
                  report: testReports.last,
                  formattedDistance: '3.4 km',
                  onClose: () => closed = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final preview = find.byType(CitizenMapPreviewCard);
      expect(preview, findsOneWidget);
      expect(
        find.descendant(of: preview, matching: find.text('PR-RUTAS-1F30E5-85')),
        findsOneWidget,
      );
      expect(
        find.text('Ver detalles del reporte').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Cerrar vista previa'));
      expect(closed, isTrue);
    },
  );
}
