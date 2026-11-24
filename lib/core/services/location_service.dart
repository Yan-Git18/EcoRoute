import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/geo_constants.dart';

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
  Future<LocationDataResult?> getCoordinatesFromAddress(String address);
}

String describeLocationCoordinates(double lat, double lng) =>
    'Ubicación seleccionada (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';

/// Implementación concreta de LocationService con Geolocator y Geocoding.
class GeolocatorLocationServiceImpl implements LocationService {
  static const double _fallbackLat = AppGeoConstants.cajamarcaCenterLat;
  static const double _fallbackLng = AppGeoConstants.cajamarcaCenterLng;
  static const String _defaultFallbackAddress = AppGeoConstants.defaultAddress;
  static const _androidLocation = MethodChannel('ecoroute/location');

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

      final coordinates = await _getCoordinates();
      if (coordinates == null) {
        return const LocationDataResult(
          latitude: _fallbackLat,
          longitude: _fallbackLng,
          address: _defaultFallbackAddress,
          errorMessage: 'El GPS no encontró tu ubicación. Puedes marcarla en el mapa.',
        );
      }

      final (latitude, longitude) = coordinates;
      final address = await getAddressFromCoordinates(latitude, longitude);

      return LocationDataResult(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
    } catch (_) {
      return const LocationDataResult(
        latitude: _fallbackLat,
        longitude: _fallbackLng,
        address: _defaultFallbackAddress,
        errorMessage: 'No se pudo obtener la ubicación. Puedes marcarla en el mapa.',
      );
    }
  }

  Future<(double, double)?> _getCoordinates() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final coordinates = await _androidLocation
          .invokeListMethod<double>('getCurrentCoordinates')
          .timeout(const Duration(seconds: 12), onTimeout: () => null);
      return coordinates == null ? null : (coordinates[0], coordinates[1]);
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return (position.latitude, position.longitude);
  }

  @override
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      if (!kIsWeb) {
        final geocoding = Geocoding();
        final placemarks = await geocoding
            .placemarkFromCoordinates(lat, lng)
            .timeout(const Duration(seconds: 5));
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final street = p.street ?? p.name ?? '';
          final subLocality = p.subLocality ?? p.locality ?? '';
          if (street.isNotEmpty) {
            return '$street${subLocality.isNotEmpty ? ', $subLocality' : ''}';
          }
        }
      }
    } catch (_) {}

    return describeLocationCoordinates(lat, lng);
  }

  @override
  Future<LocationDataResult?> getCoordinatesFromAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return null;

    try {
      if (!kIsWeb) {
        final geocoding = Geocoding();
        final query = trimmed.toLowerCase().contains('cajamarca')
            ? trimmed
            : '$trimmed, Cajamarca, Perú';
        final locations = await geocoding
            .locationFromAddress(query)
            .timeout(const Duration(seconds: 5));
        if (locations.isNotEmpty) {
          final loc = locations.first;
          final resolvedAddress = await getAddressFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          return LocationDataResult(
            latitude: loc.latitude,
            longitude: loc.longitude,
            address: resolvedAddress.isNotEmpty ? resolvedAddress : trimmed,
          );
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

/// Provider de Riverpod para LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationServiceImpl();
});
