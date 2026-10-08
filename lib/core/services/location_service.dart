import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Resultado encuadronado de una operación de ubicación GPS.
class LocationDataResult {
  final double latitude;
  final double longitude;
  final String? address;
  final String? errorMessage;
  final bool isPermissionDenied;

  const LocationDataResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.errorMessage,
    this.isPermissionDenied = false,
  });
}

/// Contrato del servicio de geolocalización y direcciones.
///
/// Responsabilidad Única: Gestionar permisos GPS, posición del dispositivo y geocodificación.
abstract class LocationService {
  Future<LocationDataResult> getCurrentPosition();
  Future<String> getAddressFromCoordinates(double lat, double lng);
}

/// Implementación concreta de LocationService con Geolocator y Geocoding.
class GeolocatorLocationServiceImpl implements LocationService {
  static const double _fallbackLat = -12.046374; // Coordenadas por defecto (Lima/Centro)
  static const double _fallbackLng = -77.042793;
  static const String _defaultFallbackAddress = 'Av. Las Palmeras 412, Centro';

  @override
  Future<LocationDataResult> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationDataResult(
          latitude: _fallbackLat,
          longitude: _fallbackLng,
          address: _defaultFallbackAddress,
          errorMessage: 'Los servicios de ubicación están desactivados.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationDataResult(
            latitude: _fallbackLat,
            longitude: _fallbackLng,
            address: _defaultFallbackAddress,
            isPermissionDenied: true,
            errorMessage: 'Permiso de ubicación denegado.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationDataResult(
          latitude: _fallbackLat,
          longitude: _fallbackLng,
          address: _defaultFallbackAddress,
          isPermissionDenied: true,
          errorMessage: 'Permiso de ubicación denegado permanentemente.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final address = await getAddressFromCoordinates(position.latitude, position.longitude);

      return LocationDataResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      return LocationDataResult(
        latitude: _fallbackLat,
        longitude: _fallbackLng,
        address: _defaultFallbackAddress,
        errorMessage: 'Error al obtener la posición GPS: $e',
      );
    }
  }

  @override
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    String resolvedAddress = 'Ubicación seleccionada (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';

    try {
      if (!kIsWeb) {
        final geocoding = Geocoding();
        final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final street = p.street ?? p.name ?? '';
          final subLocality = p.subLocality ?? p.locality ?? '';
          if (street.isNotEmpty) {
            resolvedAddress = '$street${subLocality.isNotEmpty ? ', $subLocality' : ''}';
          }
        }
      } else {
        resolvedAddress = _defaultFallbackAddress;
      }
    } catch (_) {
      resolvedAddress = _defaultFallbackAddress;
    }

    return resolvedAddress;
  }
}

/// Provider de Riverpod para LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationServiceImpl();
});
