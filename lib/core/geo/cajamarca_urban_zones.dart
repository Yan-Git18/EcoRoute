import 'package:latlong2/latlong.dart';

part 'cajamarca_urban_geometry.dart';

enum CajamarcaZone {
  central('central', 'Zona Central'),
  northwest('noroeste', 'Zona Noroeste'),
  northeast('noreste', 'Zona Noreste'),
  southwest('suroeste', 'Zona Suroeste'),
  southeast('sureste', 'Zona Sureste');

  const CajamarcaZone(this.id, this.name);

  final String id;
  final String name;

  List<List<List<LatLng>>> get polygons => _zonePolygons[this]!;

  static CajamarcaZone? fromId(String? id) =>
      values.where((zone) => zone.id == id).firstOrNull;
}

abstract final class CajamarcaUrbanZones {
  static final vertices = List<LatLng>.unmodifiable(
    CajamarcaZone.values.expand(
      (zone) => zone.polygons.expand((polygon) => polygon.first),
    ),
  );

  /// A point on a shared boundary belongs to the first zone in enum order.
  static CajamarcaZone? zoneAt(double latitude, double longitude) {
    if (!latitude.isFinite || !longitude.isFinite) return null;

    for (final zone in CajamarcaZone.values) {
      for (final polygon in zone.polygons) {
        if (_contains(polygon.first, latitude, longitude) &&
            !polygon
                .skip(1)
                .any((hole) => _contains(hole, latitude, longitude))) {
          return zone;
        }
      }
    }
    return null;
  }

  static bool _contains(List<LatLng> ring, double latitude, double longitude) {
    const tolerance = 1e-10;
    var inside = false;
    var previous = ring.last;

    for (final point in ring) {
      final dx = point.longitude - previous.longitude;
      final dy = point.latitude - previous.latitude;
      final x = longitude - previous.longitude;
      final y = latitude - previous.latitude;
      final segmentLengthSquared = dx * dx + dy * dy;
      final cross = dx * y - dy * x;
      final dot = x * dx + y * dy;

      if (segmentLengthSquared > 0 &&
          cross * cross <= tolerance * tolerance * segmentLengthSquared &&
          dot >= 0 &&
          dot <= segmentLengthSquared) {
        return true;
      }

      if ((previous.latitude > latitude) != (point.latitude > latitude) &&
          x < dx * y / dy) {
        inside = !inside;
      }
      previous = point;
    }
    return inside;
  }
}
