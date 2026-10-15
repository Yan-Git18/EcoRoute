import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecoroute/core/enums/report_filter.dart';
import 'package:ecoroute/core/services/location_service.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_category_entity.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/citizen/domain/repositories/report_repository.dart';
import 'package:ecoroute/features/citizen/presentation/viewmodels/citizen_map_viewmodel.dart';
import 'package:ecoroute/features/citizen/presentation/viewmodels/create_report_viewmodel.dart';

class FakeLocationService implements LocationService {
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

class FakeReportRepository implements ReportRepository {
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
    return Success(reports.first);
  }

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async {
    return Success(reports);
  }

  @override
  Future<Result<ReportEntity>> cancelReport({required String reportId, String? reason}) async {
    return Success(reports.first.copyWith(status: ReportStatus.cancelled));
  }
}

void main() {
  late FakeReportRepository fakeRepository;
  late FakeLocationService fakeLocationService;
  late ProviderContainer container;

  final repPending = ReportEntity(
    id: 'r-1',
    reportNumber: '#REP-001',
    citizenId: 'u-1',
    citizenName: 'Carlos',
    categoryId: 'waste_accumulation',
    categoryName: 'Acumulación de basura',
    categoryIcon: 'delete_outline_rounded',
    description: 'Basura en la esquina de Abancay',
    priority: ReportPriority.high,
    status: ReportStatus.pending,
    latitude: -12.0478,
    longitude: -77.0415,
    address: 'Av. Abancay 450',
    imageUrls: const [],
    createdAt: DateTime.now(),
  );

  final repInProgress = ReportEntity(
    id: 'r-2',
    reportNumber: '#REP-002',
    citizenId: 'u-2',
    citizenName: 'Ana',
    categoryId: 'full_bin',
    categoryName: 'Contenedor lleno',
    categoryIcon: 'delete_sweep_rounded',
    description: 'Contenedor desbordado',
    priority: ReportPriority.medium,
    status: ReportStatus.inProgress,
    latitude: -12.0452,
    longitude: -77.0435,
    address: 'Jr. de la Unión 810',
    imageUrls: const [],
    createdAt: DateTime.now(),
  );

  final repResolved = ReportEntity(
    id: 'r-3',
    reportNumber: '#REP-003',
    citizenId: 'u-3',
    citizenName: 'Luis',
    categoryId: 'waste_public_road',
    categoryName: 'Residuos en vía pública',
    categoryIcon: 'cleaning_services_rounded',
    description: 'Residuos dispersos',
    priority: ReportPriority.low,
    status: ReportStatus.resolved,
    latitude: -12.0440,
    longitude: -77.0450,
    address: 'Av. Tacna 320',
    imageUrls: const [],
    createdAt: DateTime.now(),
  );

  setUp(() {
    fakeRepository = FakeReportRepository();
    fakeRepository.reports = [repPending, repInProgress, repResolved];
    fakeLocationService = FakeLocationService();

    container = ProviderContainer(
      overrides: [
        reportRepositoryProvider.overrideWithValue(fakeRepository),
        locationServiceProvider.overrideWithValue(fakeLocationService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('carga reportes comunitarios y ubicación inicial correctamente', () async {
    final viewModel = container.read(citizenMapViewModelProvider.notifier);
    await viewModel.loadReports();
    await viewModel.requestUserLocation();

    final state = container.read(citizenMapViewModelProvider);

    expect(state.isLoading, isFalse);
    expect(state.allReports.length, equals(3));
    expect(state.userAddress, equals('Plaza Mayor de Lima'));
  });

  test('filtra adecuadamente por estado de reporte (Pending, InProgress, Resolved)', () async {
    final viewModel = container.read(citizenMapViewModelProvider.notifier);
    await viewModel.loadReports();

    // Filtro Pendientes
    viewModel.setFilter(ReportFilter.pending);
    var state = container.read(citizenMapViewModelProvider);
    expect(state.filteredReports.length, equals(1));
    expect(state.filteredReports.first.reportNumber, equals('#REP-001'));

    // Filtro En Proceso
    viewModel.setFilter(ReportFilter.inProgress);
    state = container.read(citizenMapViewModelProvider);
    expect(state.filteredReports.length, equals(1));
    expect(state.filteredReports.first.reportNumber, equals('#REP-002'));

    // Filtro Resueltos
    viewModel.setFilter(ReportFilter.resolved);
    state = container.read(citizenMapViewModelProvider);
    expect(state.filteredReports.length, equals(1));
    expect(state.filteredReports.first.reportNumber, equals('#REP-003'));

    // Filtro Todos
    viewModel.setFilter(ReportFilter.all);
    state = container.read(citizenMapViewModelProvider);
    expect(state.filteredReports.length, equals(3));
  });

  test('filtra reportes mediante el buscador de texto por dirección o categoría', () async {
    final viewModel = container.read(citizenMapViewModelProvider.notifier);
    await viewModel.loadReports();

    // Búsqueda por texto "Abancay"
    viewModel.setSearchQuery('Abancay');
    var state = container.read(citizenMapViewModelProvider);
    expect(state.filteredReports.length, equals(1));
    expect(state.filteredReports.first.address, contains('Abancay'));

    // Búsqueda por categoría "Contenedor"
    viewModel.setSearchQuery('Contenedor');
    state = container.read(citizenMapViewModelProvider);
    expect(state.filteredReports.length, equals(1));
    expect(state.filteredReports.first.categoryName, equals('Contenedor lleno'));

    // Limpiar búsqueda
    viewModel.setSearchQuery('');
    state = container.read(citizenMapViewModelProvider);
    expect(state.filteredReports.length, equals(3));
  });

  test('selecciona y deselecciona reporte para la tarjeta previa flotante', () async {
    final viewModel = container.read(citizenMapViewModelProvider.notifier);
    await viewModel.loadReports();

    // Seleccionar reporte
    viewModel.selectReport(repPending);
    var state = container.read(citizenMapViewModelProvider);
    expect(state.selectedReport, equals(repPending));

    // Deseleccionar reporte
    viewModel.selectReport(null);
    state = container.read(citizenMapViewModelProvider);
    expect(state.selectedReport, isNull);
  });

  test('alterna correctamente entre vista mapa (Vista 9) y lista de cercanos (Vista 10)', () {
    final viewModel = container.read(citizenMapViewModelProvider.notifier);

    // Inicialmente mapa
    expect(container.read(citizenMapViewModelProvider).isListView, isFalse);

    // Cambiar a lista
    viewModel.toggleViewMode(true);
    expect(container.read(citizenMapViewModelProvider).isListView, isTrue);

    // Cambiar a mapa
    viewModel.toggleViewMode(false);
    expect(container.read(citizenMapViewModelProvider).isListView, isFalse);
  });
}
