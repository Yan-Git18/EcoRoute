import 'package:ecoroute/core/services/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class _AndroidPermissions extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('ecoroute/location');
  final messenger = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger;

  setUp(() {
    final original = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = _AndroidPermissions();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() {
      GeolocatorPlatform.instance = original;
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(channel, null);
    });
  });

  test('Android consulta coordenadas por el canal nativo', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getCurrentCoordinates');
      return [-7.158, -78.518];
    });

    final result = await GeolocatorLocationServiceImpl().getCurrentPosition();

    expect(result.latitude, -7.158);
    expect(result.longitude, -78.518);
    expect(result.errorMessage, isNull);
  });

  test('Si no hay una lectura de GPS se puede continuar con el mapa', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);

    final result = await GeolocatorLocationServiceImpl().getCurrentPosition();

    expect(result.errorMessage, contains('marcarla en el mapa'));
    expect(result.isPermissionDenied, isFalse);
  });
}
