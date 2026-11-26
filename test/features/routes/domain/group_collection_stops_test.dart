import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/routes/domain/collection_route.dart';
import 'package:ecoroute/features/routes/domain/group_collection_stops.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

CollectionStop stop(String id, double longitude, {bool urgent = false}) =>
    CollectionStop(
      reportId: id,
      number: id,
      address: '',
      location: LatLng(-7.158, longitude),
      priority: urgent ? ReportPriority.high : ReportPriority.medium,
    );

void main() {
  test(
    'sugiere dos recorridos para concentraciones de cuatro y cinco reportes',
    () {
      final west = List.generate(4, (i) => stop('o$i', -78.525 + i * 0.0001));
      final east = List.generate(
        5,
        (i) => stop('e$i', -78.508 + i * 0.0001, urgent: i == 3),
      );
      final groups = const GroupCollectionStops()([...west, ...east]);

      expect(groups.map((group) => group.length), [5, 4]);
      expect(groups.first.first, east[3]);
      expect(groups.first, unorderedEquals(east));
      expect(groups.last, unorderedEquals(west));
    },
  );

  test('la proximidad por cadena no une extremos demasiado separados', () {
    final groups = const GroupCollectionStops()([
      stop('a', -78.525),
      stop('b', -78.519),
      stop('c', -78.513),
    ]);

    expect(groups.map((group) => group.length), [2, 1]);
  });

  test(
    'mantiene todos los reportes al dividir un grupo que supera el límite',
    () {
      final stops = List.generate(11, (i) => stop('$i', -78.52));
      final groups = const GroupCollectionStops()(stops);

      expect(groups.map((group) => group.length), [
        CollectionRoute.maxStops,
        1,
      ]);
      expect(groups.expand((group) => group), unorderedEquals(stops));
    },
  );

  test('los horarios consecutivos no se superponen', () {
    final start = DateTime(2026, 11, 25, 8);
    final end = DateTime(2026, 11, 25, 9);
    final window = RouteWindow(start, end);

    expect(window.overlaps(RouteWindow(start, end)), isTrue);
    expect(
      window.overlaps(RouteWindow(end, DateTime(2026, 11, 25, 10))),
      isFalse,
    );
  });
}
