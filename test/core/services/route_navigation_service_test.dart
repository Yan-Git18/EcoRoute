import 'package:ecoroute/core/services/route_navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

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

  test('Consulta las paradas por calles en el orden solicitado', () async {
    final client = MockClient((request) async {
      expect(
        request.url.path,
        contains('-78.52,-7.16;-78.51,-7.15;-78.5,-7.14'),
      );
      expect(request.url.queryParameters['overview'], 'simplified');
      return http.Response('''
        {"code":"Ok","routes":[{"distance":3000,"duration":420,
          "geometry":{"coordinates":[[-78.52,-7.16],[-78.51,-7.15],[-78.5,-7.14]]}}]}
      ''', 200);
    });
    final result = await OsrmRouteNavigationServiceImpl(client: client)
        .routeThrough(const [
          LatLng(-7.16, -78.52),
          LatLng(-7.15, -78.51),
          LatLng(-7.14, -78.5),
        ]);

    expect(result?.points, hasLength(3));
    expect(result?.distanceMeters, 3000);
    expect(result?.durationSeconds, 420);
  });

  test(
    'Consulta tiempos por sentido y conserva los tramos sin conexión',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/table/v1/driving/-78.52,-7.16;-78.51,-7.15');
        expect(request.url.queryParameters['annotations'], 'duration');
        return http.Response(
          '{"code":"Ok","durations":[[0,27.3],[null,0]]}',
          200,
        );
      });
      final matrix = await OsrmRouteNavigationServiceImpl(
        client: client,
      ).travelTimes(const [LatLng(-7.16, -78.52), LatLng(-7.15, -78.51)]);
      expect(matrix, [
        [0, 27.3],
        [null, 0],
      ]);
    },
  );
}
