import '../../../core/services/route_navigation_service.dart';
import 'collection_route.dart';

typedef CollectionRouteProposal = ({
  List<CollectionStop> stops,
  RouteInfoResult? road,
});

Future<CollectionRouteProposal> optimizeCollectionStops(
  List<CollectionStop> stops,
  WaypointRoutingService routing,
) async {
  final original = List<CollectionStop>.unmodifiable(stops);
  if (original.length < 2) return (stops: original, road: null);
  final points = original.map((stop) => stop.location).toList();
  final baseline = routing.routeThrough(points);
  if (original.length < 3 || routing is! RoadTravelTimeService) {
    return (stops: original, road: await baseline);
  }

  final matrix = await (routing as RoadTravelTimeService).travelTimes(points);
  final order = matrix == null ? null : _shortestOrder(matrix);
  final previousRoad = await baseline;
  if (order == null) return (stops: original, road: previousRoad);

  final reordered = List<CollectionStop>.unmodifiable(
    order.map((index) => original[index]),
  );
  final road = await routing.routeThrough(
    reordered.map((stop) => stop.location).toList(),
  );
  if (road == null ||
      (previousRoad != null &&
          road.durationSeconds >= previousRoad.durationSeconds)) {
    return (stops: original, road: previousRoad);
  }
  return (stops: reordered, road: road);
}

// Keep the planner's first stop and find the fastest open path from there.
List<int>? _shortestOrder(List<List<double?>> times) {
  final count = times.length;
  final allVisited = (1 << count) - 1;
  final cost = List.generate(
    1 << count,
    (_) => List.filled(count, double.infinity),
  );
  final predecessor = List.generate(1 << count, (_) => List.filled(count, -1));
  cost[1][0] = 0;
  for (var visited = 1; visited <= allVisited; visited += 2) {
    for (var from = 0; from < count; from++) {
      if (!cost[visited][from].isFinite) continue;
      for (var to = 1; to < count; to++) {
        final bit = 1 << to;
        final leg = times[from][to];
        if ((visited & bit) != 0 || leg == null || !leg.isFinite || leg < 0) {
          continue;
        }
        final next = visited | bit;
        final duration = cost[visited][from] + leg;
        if (duration < cost[next][to]) {
          cost[next][to] = duration;
          predecessor[next][to] = from;
        }
      }
    }
  }

  var baseline = 0.0;
  for (var index = 1; index < count; index++) {
    baseline += times[index - 1][index] ?? double.infinity;
  }
  var best = baseline;
  var last = -1;
  for (var index = 1; index < count; index++) {
    if (cost[allVisited][index] < best) {
      best = cost[allVisited][index];
      last = index;
    }
  }
  if (last < 0) return null;

  final reversed = <int>[];
  var visited = allVisited;
  while (last >= 0) {
    reversed.add(last);
    final previous = predecessor[visited][last];
    visited ^= 1 << last;
    last = previous;
  }
  return reversed.reversed.toList();
}
