import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Configuración geográfica y delimitación territorial para EcoRoute Cajamarca, Perú.
///
/// Establece los límites geográficos (bounding box), centro urbano de Cajamarca
/// y restricciones de cámara para garantizar que todos los reportes pertenezcan
/// exclusivamente al ámbito geográfico de cobertura y evitar reportes falsos fuera de la ciudad.
class AppGeoConstants {
  AppGeoConstants._();

  /// Nombre de la ciudad de operación
  static const String cityName = 'Cajamarca';
  static const String departmentName = 'Cajamarca';
  static const String countryName = 'Perú';

  /// Coordenadas de la Plaza de Armas / Centro Histórico de Cajamarca
  static const double cajamarcaCenterLat = -7.1580;
  static const double cajamarcaCenterLng = -78.5180;
  static const LatLng cajamarcaCenter = LatLng(cajamarcaCenterLat, cajamarcaCenterLng);

  /// Dirección urbana de referencia por defecto
  static const String defaultAddress = 'Jr. Del Comercio 620, Centro Histórico, Cajamarca';

  /// Límites de cobertura urbana y periurbana (Distrito de Cajamarca + Baños del Inca)
  ///
  /// - Límite Sur: Hacia salida a Jesús / Huacariz (-7.2350)
  /// - Límite Norte: Hacia Bellavista / salida Porcón (-7.0900)
  /// - Límite Oeste: Colina Santa Apolonia / Cumbemayo (-7.5750)
  /// - Límite Este: Baños del Inca / Otuzco (-78.4300)
  static const double minLat = -7.2350;
  static const double maxLat = -7.0900;
  static const double minLng = -78.5750;
  static const double maxLng = -78.4300;

  /// Nivel de zoom por defecto y límites
  static const double defaultZoom = 15.0;
  static const double minZoom = 12.0; // Impide alejar la cámara hacia otros departamentos o países
  static const double maxZoom = 18.5; // Nivel de detalle callejero exacto

  /// Bounding Box oficial de cobertura de Cajamarca
  static final LatLngBounds cajamarcaBounds = LatLngBounds(
    const LatLng(minLat, minLng),
    const LatLng(maxLat, maxLng),
  );

  /// Restricción de cámara para FlutterMap (impide navegar físicamente fuera de Cajamarca)
  static final CameraConstraint cameraConstraint = CameraConstraint.containCenter(
    bounds: cajamarcaBounds,
  );

  /// Valida si unas coordenadas (latitud, longitud) caen dentro del área de cobertura de Cajamarca.
  static bool isInsideCajamarca(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }
}
