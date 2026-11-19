import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Resultado inmutable del cálculo de ruta óptima hacia un reporte ciudadano.
///
/// Contiene el trazado de coordenadas (polilínea), distancia total en metros
/// y tiempo estimado de llegada (ETA) en segundos.
///
/// Ubicación: `lib/core/services/route_navigation_service.dart`
/// Capa: Core (Services)
class RouteInfoResult {
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;

  const RouteInfoResult({
    required this.origin,
    required this.destination,
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// Distancia formateada legible para la interfaz (ej. '450 m' o '1.8 km').
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  /// Tiempo estimado de llegada formateado (ej. '~4 min' o '1 h 10 min').
  String get formattedDuration {
    if (distanceMeters < 15) {
      return '< 1 min';
    }
    final minutes = math.max(1, (durationSeconds / 60).ceil());
    if (minutes < 60) {
      return '~$minutes min';
    }
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;
    return remMinutes > 0 ? '$hours h $remMinutes min' : '$hours h';
  }
}

/// Contrato del servicio de cálculo de rutas óptimas para el personal operativo.
///
/// Principio SRP / DIP: Encapsula la obtención del recorrido vial óptimo,
/// distancia y tiempo estimado entre la ubicación actual del trabajador y el reporte.
abstract class RouteNavigationService {
  Future<RouteInfoResult> calculateOptimalRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  });
}

/// Implementación concreta de [RouteNavigationService] que consulta el motor
/// de enrutamiento vial Open Source Routing Machine (OSRM) sobre OpenStreetMap,
/// con respaldo geodésico automático para entornos sin conexión o pruebas.
class OsrmRouteNavigationServiceImpl implements RouteNavigationService {
  bool get _isFlutterTest {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  Future<RouteInfoResult> calculateOptimalRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final origin = LatLng(originLat, originLng);
    final destination = LatLng(destLat, destLng);

    // En modo de pruebas unitarias/widgets o web sin CORS, usar cálculo geodésico directo
    if (!_isFlutterTest && !kIsWeb) {
      final osrmRoute = await _fetchOsrmDrivingRoute(
        origin: origin,
        destination: destination,
      );
      if (osrmRoute != null) {
        return osrmRoute;
      }
    }

    return _buildGeodesicFallbackRoute(
      origin: origin,
      destination: destination,
    );
  }

  /// Consulta la ruta vial óptima en servidores OSRM (OpenStreetMap road network),
  /// devolviendo todos los vértices reales de las calles (GeoJSON).
  Future<RouteInfoResult?> _fetchOsrmDrivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final endpoints = <String>[
      'https://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson&steps=true',
      'https://routing.openstreetmap.de/routed-car/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson&steps=true',
    ];

    for (final url in endpoints) {
      final result = await _queryOsrmEndpoint(
        url: url,
        origin: origin,
        destination: destination,
      );
      if (result != null && result.points.length > 2) {
        return result;
      }
    }
    return null;
  }

  Future<RouteInfoResult?> _queryOsrmEndpoint({
    required String url,
    required LatLng origin,
    required LatLng destination,
  }) async {
    HttpClient? client;
    try {
      final uri = Uri.parse(url);

      client = HttpClient()..connectionTimeout = const Duration(seconds: 7);
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 7));
      request.headers.set(HttpHeaders.userAgentHeader, 'EcoRouteApp/1.0');
      final response = await request.close().timeout(const Duration(seconds: 7));

      if (response.statusCode != 200) {
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') {
        return null;
      }

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return null;
      }

      final bestRoute = routes.first as Map<String, dynamic>;
      final distanceMeters = (bestRoute['distance'] as num?)?.toDouble() ?? 0.0;
      final durationSeconds = (bestRoute['duration'] as num?)?.round() ?? 0;

      final geometry = bestRoute['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;

      final routePoints = <LatLng>[];
      if (coordinates != null && coordinates.isNotEmpty) {
        for (final coord in coordinates) {
          if (coord is List && coord.length >= 2) {
            final lng = (coord[0] as num).toDouble();
            final lat = (coord[1] as num).toDouble();
            routePoints.add(LatLng(lat, lng));
          }
        }
      }

      if (routePoints.length < 2) {
        return null;
      }

      return RouteInfoResult(
        origin: origin,
        destination: destination,
        points: routePoints,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds > 0
            ? durationSeconds
            : _estimateDurationSeconds(distanceMeters),
      );
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  /// Respaldo geodésico cuando el dispositivo no tiene internet o está en entorno de test.
  RouteInfoResult _buildGeodesicFallbackRoute({
    required LatLng origin,
    required LatLng destination,
  }) {
    final distanceMeters = _calculateDistanceMeters(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    final durationSeconds = _estimateDurationSeconds(distanceMeters);

    return RouteInfoResult(
      origin: origin,
      destination: destination,
      points: <LatLng>[origin, destination],
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
  }

  double _calculateDistanceMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    try {
      return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    } catch (_) {
      // Fórmula de Haversine pura de respaldo
      const earthRadiusMeters = 6371000.0;
      final dLat = _degToRad(endLat - startLat);
      final dLng = _degToRad(endLng - startLng);
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(_degToRad(startLat)) *
              math.cos(_degToRad(endLat)) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      return earthRadiusMeters * c;
    }
  }

  int _estimateDurationSeconds(double distanceMeters) {
    if (distanceMeters <= 10) return 0;
    // Velocidad urbana promedio de unidad de recolección: ~25 km/h (6.94 m/s)
    const urbanSpeedMetersPerSecond = 6.94;
    return math.max(60, (distanceMeters / urbanSpeedMetersPerSecond).round());
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}

/// Provider de Riverpod para [RouteNavigationService].
final routeNavigationServiceProvider = Provider<RouteNavigationService>((ref) {
  return OsrmRouteNavigationServiceImpl();
});

