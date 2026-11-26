import 'package:ecoroute/core/geo/cajamarca_urban_zones.dart';
import 'package:ecoroute/core/services/route_navigation_service.dart';
import 'package:ecoroute/features/admin/domain/entities/municipal_crew_entity.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_route_providers.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_route_planner_screen.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_route_review_screen.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/routes/domain/collection_route.dart';
import 'package:ecoroute/features/routes/domain/collection_route_repository.dart';
import 'package:ecoroute/features/routes/presentation/collection_route_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets(
    'Planifica dos propuestas de cuatro y cinco paradas en una zona',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stops = List.generate(
        9,
        (index) => CollectionStop(
          reportId: 'reporte-$index',
          number: '#$index',
          address: 'Dirección $index',
          location: LatLng(-7.158, index < 4 ? -78.523 : -78.509),
          priority: index == 4 ? ReportPriority.high : ReportPriority.medium,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eligibleRouteReportsProvider.overrideWithValue(
              AsyncData({CajamarcaZone.central: stops}),
            ),
          ],
          child: const MaterialApp(home: AdminRoutePlannerScreen()),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<CajamarcaZone>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zona Central · 9 disponibles').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      expect(find.text('1 de 9 seleccionados'), findsOneWidget);
      await tester.tap(find.text('Mapa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpiar selección'));
      await tester.pumpAndSettle();
      expect(find.text('0 de 9 seleccionados'), findsOneWidget);
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpiar selección'));
      await tester.pumpAndSettle();
      expect(find.text('0 de 9 seleccionados'), findsOneWidget);
      await tester.tap(find.text('Seleccionar todos'));
      await tester.pumpAndSettle();
      final generate = find.text('Generar propuestas');
      final buttonPosition = tester.getCenter(generate);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.getCenter(generate), buttonPosition);
      await tester.tap(generate);
      await tester.pumpAndSettle();

      expect(find.text('2 propuestas · 9 reportes'), findsOneWidget);
      expect(find.text('5 paradas'), findsOneWidget);
      expect(find.text('4 paradas'), findsOneWidget);
      expect(find.textContaining('Revisar y asignar ruta'), findsOneWidget);
    },
  );

  testWidgets(
    'Confirma la ruta con las paradas reordenadas y el equipo elegido',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _PlanningRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            collectionRouteRepositoryProvider.overrideWithValue(repository),
            waypointRoutingProvider.overrideWithValue(_UnavailableRouting()),
            routeCrewsProvider.overrideWith(
              (ref) async => const [
                MunicipalCrewEntity(
                  id: 'equipo-1',
                  name: 'Equipo 01',
                  zone: '',
                  leadStaffName: 'Líder',
                  vehicleCode: 'C01',
                  vehiclePlate: 'ABC-123',
                ),
              ],
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const AdminRouteReviewScreen(
                        zone: CajamarcaZone.central,
                        initialName: 'Ruta central',
                        stops: [
                          CollectionStop(
                            reportId: 'r1',
                            number: '#1',
                            address: 'Primera calle',
                            location: LatLng(-7.158, -78.523),
                            priority: ReportPriority.medium,
                          ),
                          CollectionStop(
                            reportId: 'r2',
                            number: '#2',
                            address: 'Segunda calle',
                            location: LatLng(-7.158, -78.522),
                            priority: ReportPriority.high,
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: const Text('Revisar'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Revisar'));
      await tester.pumpAndSettle();
      expect(find.text('Recorrido por calles no disponible.'), findsOneWidget);
      await tester.tap(find.byTooltip('Bajar parada').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asignar y programar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Equipo 01 · ABC-123').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar planificación'));
      await tester.pumpAndSettle();

      expect(repository.saved?.stops.map((stop) => stop.reportId), [
        'r2',
        'r1',
      ]);
      expect(repository.savedCrewId, 'equipo-1');
      expect(repository.saved?.durationSeconds, isNull);
      expect(find.text('Revisar'), findsOneWidget);
    },
  );
}

class _PlanningRepository implements CollectionRouteRepository {
  RouteDraft? saved;
  String? savedCrewId;

  @override
  Stream<List<CollectionRoute>> watchRoutes({String? crewId}) =>
      Stream.value(const []);

  @override
  Future<void> plan(RouteDraft draft, String crewId, RouteWindow window) async {
    saved = draft;
    savedCrewId = crewId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnavailableRouting implements WaypointRoutingService {
  @override
  Future<RouteInfoResult?> routeThrough(List<LatLng> stops) async => null;
}
