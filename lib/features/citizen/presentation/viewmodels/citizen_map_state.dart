import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/geo_constants.dart';
import '../../../../core/enums/report_filter.dart';
import '../../domain/entities/report_entity.dart';

/// Estado inmutable para la pantalla de Mapa y Reportes Cercanos del rol Ciudadano.
///
/// Ubicación: `lib/features/citizen/presentation/viewmodels/citizen_map_state.dart`
/// Capa: Presentation (ViewModel State)
class CitizenMapState {
  final bool isLoading;
  final bool isLocating;
  final List<ReportEntity> allReports;
  final String searchQuery;
  final ReportFilter selectedFilter;
  final ReportEntity? selectedReport;
  final double userLatitude;
  final double userLongitude;
  final String userAddress;
  final bool isListView;
  final String? errorMessage;

  const CitizenMapState({
    this.isLoading = true,
    this.isLocating = false,
    this.allReports = const [],
    this.searchQuery = '',
    this.selectedFilter = ReportFilter.all,
    this.selectedReport,
    this.userLatitude = AppGeoConstants.cajamarcaCenterLat,
    this.userLongitude = AppGeoConstants.cajamarcaCenterLng,
    this.userAddress = 'Centro de Cajamarca',
    this.isListView = false,
    this.errorMessage,
  });

  /// Lista de reportes filtrados por término de búsqueda y estado seleccionado.
  List<ReportEntity> get filteredReports {
    var list = allReports;

    // Filtro por estado
    if (selectedFilter != ReportFilter.all) {
      list = list.where((report) {
        switch (selectedFilter) {
          case ReportFilter.pending:
            return report.status == ReportStatus.pending;
          case ReportFilter.inProgress:
            return report.status == ReportStatus.inProgress ||
                report.status == ReportStatus.assigned;
          case ReportFilter.resolved:
            return report.status == ReportStatus.resolved;
          case ReportFilter.all:
            return true;
        }
      }).toList();
    }

    // Filtro por texto de búsqueda (número, categoría, dirección o descripción)
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      list = list.where((report) {
        return report.reportNumber.toLowerCase().contains(query) ||
            report.categoryName.toLowerCase().contains(query) ||
            report.address.toLowerCase().contains(query) ||
            report.description.toLowerCase().contains(query);
      }).toList();
    }

    return list;
  }

  /// Lista de reportes ordenados por proximidad al usuario (para la Vista 10: Lista de cercanos).
  List<ReportEntity> get nearbyReports {
    final list = List<ReportEntity>.from(filteredReports);
    list.sort((a, b) {
      final distA = distanceToReport(a);
      final distB = distanceToReport(b);
      return distA.compareTo(distB);
    });
    return list;
  }

  /// Calcula la distancia geodésica en metros entre la posición del usuario y un reporte.
  double distanceToReport(ReportEntity report) {
    if (report.latitude == 0.0 && report.longitude == 0.0) return 0.0;
    try {
      return Geolocator.distanceBetween(
        userLatitude,
        userLongitude,
        report.latitude,
        report.longitude,
      );
    } catch (_) {
      return 0.0;
    }
  }

  /// Retorna la distancia formateada para visualización amigable ('250 m' o '1.8 km').
  String formattedDistanceToReport(ReportEntity report) {
    final meters = distanceToReport(report);
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  CitizenMapState copyWith({
    bool? isLoading,
    bool? isLocating,
    List<ReportEntity>? allReports,
    String? searchQuery,
    ReportFilter? selectedFilter,
    ReportEntity? selectedReport,
    bool clearSelectedReport = false,
    double? userLatitude,
    double? userLongitude,
    String? userAddress,
    bool? isListView,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CitizenMapState(
      isLoading: isLoading ?? this.isLoading,
      isLocating: isLocating ?? this.isLocating,
      allReports: allReports ?? this.allReports,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedReport: clearSelectedReport ? null : (selectedReport ?? this.selectedReport),
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      userAddress: userAddress ?? this.userAddress,
      isListView: isListView ?? this.isListView,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
