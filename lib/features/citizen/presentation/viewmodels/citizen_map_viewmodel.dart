import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/geo_constants.dart';
import '../../../../core/enums/report_filter.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/usecases/get_all_reports_use_case.dart';
import 'citizen_map_state.dart';
import 'create_report_viewmodel.dart';
import 'my_reports_viewmodel.dart';

// --- Inyección de Dependencias con Riverpod ---

final getAllReportsUseCaseProvider = Provider<GetAllReportsUseCase>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return GetAllReportsUseCase(repository);
});

final citizenMapViewModelProvider =
    NotifierProvider<CitizenMapViewModel, CitizenMapState>(
      CitizenMapViewModel.new,
    );

final citizenMapOwnReportsProvider = FutureProvider.autoDispose
    .family<Result<List<ReportEntity>>, String>(
      (ref, citizenId) => ref.watch(getMyReportsUseCaseProvider)(citizenId),
    );

// --- ViewModel (MVVM) ---

/// ViewModel para gestionar el mapa ciudadano.
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
  Future<void>? _activeLoad;

  @override
  CitizenMapState build() {
    _getAllReportsUseCase = ref.watch(getAllReportsUseCaseProvider);
    _locationService = ref.watch(locationServiceProvider);
    _isDisposed = false;

    ref.onDispose(() {
      _isDisposed = true;
    });

    // La pantalla solicita los reportes al entrar. El GPS no bloquea esa consulta.
    Future.microtask(() async {
      if (_isDisposed) return;
      await requestUserLocation();
    });

    return const CitizenMapState(isLoading: true);
  }

  Future<void> loadReports() => _activeLoad ??= _loadReports().whenComplete(() {
    _activeLoad = null;
  });

  /// Carga los reportes comunitarios recientes para el mapa.
  Future<void> _loadReports() async {
    if (_isDisposed) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getAllReportsUseCase();
    if (_isDisposed) return;

    result.fold(
      onSuccess: (reports) {
        if (!_isDisposed) {
          state = state.copyWith(allReports: reports, isLoading: false);
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
      final isInside = AppGeoConstants.isInsideCajamarca(
        loc.latitude,
        loc.longitude,
      );
      state = state.copyWith(
        userLatitude: isInside
            ? loc.latitude
            : AppGeoConstants.cajamarcaCenterLat,
        userLongitude: isInside
            ? loc.longitude
            : AppGeoConstants.cajamarcaCenterLng,
        userAddress: isInside
            ? (loc.address ?? state.userAddress)
            : AppGeoConstants.defaultAddress,
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

  /// Recarga manual de los reportes comunitarios.
  Future<void> refresh() async {
    await loadReports();
  }
}
