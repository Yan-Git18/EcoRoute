import 'package:ecoroute/core/services/route_navigation_service.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/routes/domain/collection_route.dart';
import 'package:ecoroute/features/routes/domain/optimize_collection_stops.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  final stops = List.generate(
    3,
    (index) => CollectionStop(
      reportId: '$index',
      number: '$index',
      address: '',
      location: LatLng(-7.15, -78.5 + index * 0.001),
      priority: ReportPriority.medium,
    ),
  );

  test('prioriza el tiempo por calles y conserva la primera parada', () async {
    final proposal = await optimizeCollectionStops(stops, const _RoadRouting(40));
    expect(proposal.stops, [stops[0], stops[2], stops[1]]);
    expect(proposal.road?.durationSeconds, 40);
  });

  test('conserva el orden si el trazado alternativo tarda más', () async {
    final proposal = await optimizeCollectionStops(stops, const _RoadRouting(120));
    expect(proposal.stops, stops);
    expect(proposal.road?.durationSeconds, 100);
  });
}

class _RoadRouting implements WaypointRoutingService, RoadTravelTimeService {
  const _RoadRouting(this.alternativeDuration);

  final int alternativeDuration;

  @override
  Future<List<List<double?>>> travelTimes(List<LatLng> stops) async => const [
    [0, 45, 20],
    [10, 0, 55],
    [null, 20, 0],
  ];

  @override
  Future<RouteInfoResult> routeThrough(List<LatLng> stops) async {
    final reordered = stops[1].longitude > stops[2].longitude;
    return RouteInfoResult(
      origin: stops.first,
      destination: stops.last,
      points: stops,
      distanceMeters: 400,
      durationSeconds: reordered ? alternativeDuration : 100,
    );
  }
}
