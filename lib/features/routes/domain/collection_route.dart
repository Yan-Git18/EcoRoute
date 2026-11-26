import 'package:latlong2/latlong.dart';

import '../../../core/geo/cajamarca_urban_zones.dart';
import '../../citizen/domain/entities/report_entity.dart';

enum CollectionRouteStatus {
  planned('Planificada'),
  inProgress('En curso'),
  completed('Finalizada'),
  cancelled('Cancelada');

  const CollectionRouteStatus(this.label);

  final String label;
}

class CollectionStop {
  const CollectionStop({
    required this.reportId,
    required this.number,
    required this.address,
    required this.location,
    required this.priority,
    this.category = '',
  });

  factory CollectionStop.fromReport(ReportEntity report) => CollectionStop(
    reportId: report.id,
    number: report.reportNumber,
    address: report.address,
    location: LatLng(report.latitude, report.longitude),
    priority: report.priority,
    category: report.categoryName,
  );

  final String reportId;
  final String number;
  final String address;
  final LatLng location;
  final ReportPriority priority;
  final String category;
}

class RouteWindow {
  const RouteWindow(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool get isValid => start.isBefore(end);

  bool overlaps(RouteWindow other) =>
      start.isBefore(other.end) && other.start.isBefore(end);
}

class CollectionRoute {
  const CollectionRoute({
    required this.id,
    required this.name,
    required this.zone,
    required this.crewId,
    required this.crewName,
    required this.vehicle,
    required this.window,
    required this.stops,
    required this.completedStops,
    this.skippedStops = const {},
    required this.status,
    required this.geometry,
    this.distanceMeters,
    this.durationSeconds,
  });

  // The Firestore route creation rule enforces this same limit.
  static const maxStops = 10;

  final String id;
  final String name;
  final CajamarcaZone zone;
  final String crewId;
  final String crewName;
  final String vehicle;
  final RouteWindow window;
  final List<CollectionStop> stops;
  // Number of stops with a recorded outcome, including skips.
  final int completedStops;
  final Map<String, String> skippedStops;
  final CollectionRouteStatus status;
  final List<LatLng> geometry;
  final double? distanceMeters;
  final int? durationSeconds;

  CollectionStop? get nextStop => stops.elementAtOrNull(completedStops);
}

class RouteDraft {
  const RouteDraft({
    required this.name,
    required this.zone,
    required this.stops,
    required this.geometry,
    this.distanceMeters,
    this.durationSeconds,
  });

  final String name;
  final CajamarcaZone zone;
  final List<CollectionStop> stops;
  final List<LatLng> geometry;
  final double? distanceMeters;
  final int? durationSeconds;
}
