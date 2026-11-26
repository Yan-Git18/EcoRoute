import 'package:latlong2/latlong.dart';

import 'collection_route.dart';

class GroupCollectionStops {
  const GroupCollectionStops({this.maxSeparationMeters = 1200});

  final double maxSeparationMeters;
  static const _distance = Distance(roundResult: false);

  List<List<CollectionStop>> call(Iterable<CollectionStop> stops) {
    final remaining = stops.toList()
      ..sort((a, b) {
        final priority = b.priority.index.compareTo(a.priority.index);
        return priority == 0 ? a.reportId.compareTo(b.reportId) : priority;
      });
    final groups = <List<CollectionStop>>[];

    while (remaining.isNotEmpty) {
      final group = [remaining.removeAt(0)];
      while (group.length < CollectionRoute.maxStops) {
        final next = _nearestCompatible(group, remaining);
        if (next == null) break;
        group.add(next);
        remaining.remove(next);
      }
      groups.add(group);
    }

    return groups;
  }

  CollectionStop? _nearestCompatible(
    List<CollectionStop> group,
    List<CollectionStop> candidates,
  ) {
    CollectionStop? nearest;
    var nearestDistance = double.infinity;
    for (final candidate in candidates) {
      if (group.any(
        (stop) =>
            _distance(stop.location, candidate.location) > maxSeparationMeters,
      )) {
        continue;
      }
      final distance = _distance(group.last.location, candidate.location);
      if (distance < nearestDistance) {
        nearest = candidate;
        nearestDistance = distance;
      }
    }
    return nearest;
  }
}
