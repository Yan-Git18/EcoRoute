import 'package:ecoroute/core/services/route_navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Acepta un trazado vial válido de dos puntos', () async {
    final client = MockClient((request) async {
      expect(request.url.path, contains('-78.52,-7.16;-78.51,-7.15'));
      return http.Response('''
        {"code":"Ok","routes":[{"distance":1700,"duration":260,
          "geometry":{"coordinates":[[-78.52,-7.16],[-78.51,-7.15]]}}]}
      ''', 200);
    });
    final route = await OsrmRouteNavigationServiceImpl(client: client)
        .calculateOptimalRoute(
          originLat: -7.16,
          originLng: -78.52,
          destLat: -7.15,
          destLng: -78.51,
        );

    expect(route.isApproximate, isFalse);
    expect(route.points, hasLength(2));
    expect(route.distanceMeters, 1700);
  });

  test(
    'Identifica el trazado aproximado si no responde el servicio vial',
    () async {
      final client = MockClient((_) async => http.Response('', 503));
      final route = await OsrmRouteNavigationServiceImpl(client: client)
          .calculateOptimalRoute(
            originLat: -7.16,
            originLng: -78.52,
            destLat: -7.15,
            destLng: -78.51,
          );

      expect(route.isApproximate, isTrue);
      expect(route.points, [route.origin, route.destination]);
    },
  );
}
