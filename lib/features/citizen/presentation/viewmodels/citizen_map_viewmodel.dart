import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/report_filter.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/usecases/get_all_reports_use_case.dart';
import 'citizen_map_state.dart';
import 'create_report_viewmodel.dart';

// --- Inyección de Dependencias con Riverpod ---

final getAllReportsUseCaseProvider = Provider<GetAllReportsUseCase>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return GetAllReportsUseCase(repository);
});

final citizenMapViewModelProvider =
    NotifierProvider<CitizenMapViewModel, CitizenMapState>(CitizenMapViewModel.new);

// --- ViewModel (MVVM) ---

/// ViewModel para gestionar el mapa comunitario interactivo y la vista de reportes cercanos.
///
/// Principios SOLID:
/// - SRP: Responsabilidad única de coordinar el estado de mapa, filtros, geolocalización y selección.
/// - DIP: Depende de abstracciones (GetAllReportsUseCase, LocationService).
///
/// Ubicación: `lib/features/citizen/presentation/viewmodels/citizen_map_viewmodel.dart`
/// Capa: Presentation (ViewModel)
class CitizenMapViewModel extends Notifier<CitizenMapState> {
  late final GetAllReportsUseCase _getAllReportsUseCase;
  late final LocationService _locationService;
  bool _isDisposed = false;

  @override
  CitizenMapState build() {
    _getAllReportsUseCase = ref.watch(getAllReportsUseCaseProvider);
    _locationService = ref.watch(locationServiceProvider);
    _isDisposed = false;

    ref.onDispose(() {
      _isDisposed = true;
    });

    // Cargar datos y geolocalizar al inicializar
    Future.microtask(() async {
      if (_isDisposed) return;
      await loadReports();
      if (_isDisposed) return;
      await requestUserLocation();
    });

    return const CitizenMapState(isLoading: true);
  }

  /// Carga todos los reportes comunitarios para el mapa y lista de cercanos.
  Future<void> loadReports() async {
    if (_isDisposed) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getAllReportsUseCase();
    if (_isDisposed) return;

    result.fold(
      onSuccess: (reports) {
        if (!_isDisposed) {
          state = state.copyWith(
            allReports: reports,
            isLoading: false,
          );
        }
      },
      onFailure: (failure) {
        if (!_isDisposed) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        }
      },
    );
  }

  /// Solicita la ubicación GPS actual del usuario mediante [LocationService].
  Future<void> requestUserLocation() async {
    if (_isDisposed) return;
    state = state.copyWith(isLocating: true);

    try {
      final loc = await _locationService.getCurrentPosition();
      if (_isDisposed) return;
      state = state.copyWith(
        userLatitude: loc.latitude,
        userLongitude: loc.longitude,
        userAddress: loc.address ?? state.userAddress,
        isLocating: false,
      );
    } catch (_) {
      if (!_isDisposed) {
        state = state.copyWith(isLocating: false);
      }
    }
  }

  /// Establece el término de búsqueda de texto.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Cambia el filtro de estado (Todos, Pendientes, En proceso, Resueltos).
  void setFilter(ReportFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  /// Selecciona un reporte para visualizar en la tarjeta emergente flotante del mapa.
  void selectReport(ReportEntity? report) {
    if (report == null) {
      state = state.copyWith(clearSelectedReport: true);
    } else {
      state = state.copyWith(selectedReport: report);
    }
  }

  /// Alterna entre Vista Mapa (false - Vista 9) y Vista Lista Cercanos (true - Vista 10).
  void toggleViewMode(bool isListView) {
    state = state.copyWith(isListView: isListView);
  }

  /// Recarga manual de datos (Pull to refresh).
  Future<void> refresh() async {
    await loadReports();
  }
}
