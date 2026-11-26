import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../geo/cajamarca_urban_zones.dart';

/// Configuración geográfica y delimitación territorial para EcoRoute Cajamarca, Perú.
///
/// Agrupa el centro de referencia, los límites de cámara y la validación
/// de cobertura urbana que usa la aplicación.
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

  /// Nivel de zoom por defecto y límites
  static const double defaultZoom = 15.0;
  static const double minZoom = 12.0; // Impide alejar la cámara hacia otros departamentos o países
  static const double maxZoom = 18.5; // Nivel de detalle callejero exacto

  /// Rectángulo que contiene los cinco sectores urbanos.
  static final LatLngBounds cajamarcaBounds = LatLngBounds.fromPoints(
    CajamarcaUrbanZones.vertices,
  );

  /// Restricción de cámara para FlutterMap (impide navegar físicamente fuera de Cajamarca)
  static final CameraConstraint cameraConstraint = CameraConstraint.containCenter(
    bounds: cajamarcaBounds,
  );

  /// Valida si unas coordenadas (latitud, longitud) caen dentro del área de cobertura de Cajamarca.
  static bool isInsideCajamarca(double lat, double lng) =>
      CajamarcaUrbanZones.zoneAt(lat, lng) != null;
}
