import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ecoroute/core/geo/cajamarca_urban_zones.dart';
import 'package:ecoroute/features/routes/domain/collection_route.dart';
import 'package:ecoroute/features/routes/presentation/collection_route_map.dart';
import 'package:ecoroute/features/routes/presentation/collection_route_providers.dart';
import 'package:ecoroute/core/services/location_service.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/staff/domain/entities/staff_operations.dart';
import 'package:ecoroute/features/staff/domain/entities/staff_task_entity.dart';
import 'package:ecoroute/features/staff/domain/repositories/staff_repository.dart';
import 'package:ecoroute/features/staff/presentation/viewmodels/staff_home_viewmodel.dart';
import 'package:ecoroute/features/staff/presentation/viewmodels/staff_navigation_link.dart';
import 'package:ecoroute/features/staff/presentation/viewmodels/staff_operations_providers.dart';
import 'package:ecoroute/features/staff/presentation/views/staff_route_map_screen.dart';
import 'package:ecoroute/features/staff/presentation/widgets/staff_bottom_nav_bar.dart';

class MockStaffAuthViewModel extends AuthViewModel {
  final UserEntity? testUser;
  MockStaffAuthViewModel(this.testUser);

  @override
  AuthState build() {
    return AuthState(
      user: testUser,
      isInitialized: true,
    );
  }
}

class MockStaffLocationService implements LocationService {
  @override
  Future<LocationDataResult> getCurrentPosition() async {
    return const LocationDataResult(
      latitude: -7.1644,
      longitude: -78.5105,
      address: 'Base de Operaciones Municipal',
    );
  }

  @override
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    return 'Base de Operaciones Municipal';
  }

  @override
  Future<LocationDataResult?> getCoordinatesFromAddress(String address) async {
    return const LocationDataResult(
      latitude: -7.1644,
      longitude: -78.5105,
      address: 'Base de Operaciones Municipal',
    );
  }
}

class MockStaffRepository implements StaffRepository {
  List<StaffTaskEntity> tasks = [];

  @override
  Future<Result<List<StaffTaskEntity>>> getAssignedTasks(String staffId) async {
    return Success(tasks);
  }

  @override
  Future<Result<StaffTaskEntity>> getTaskById(String taskId) async {
    final match = tasks.firstWhere((t) => t.id == taskId);
    return Success(match);
  }

  @override
  Future<Result<StaffTaskEntity>> updateTaskStatus({
    required String taskId,
    required String staffId,
    required String staffName,
    required ReportStatus newStatus,
    String? notes,
    String? evidenceImageUrl,
  }) async {
    final match = tasks.firstWhere((t) => t.id == taskId);
    final updated = match.copyWith(status: newStatus);
    return Success(updated);
  }

  @override
  Future<Result<StaffTaskEntity>> completeTaskWithEvidence({
    required String taskId,
    required String staffId,
    required String staffName,
    List<int>? evidenceImageBytes,
    List<List<int>>? multipleEvidenceBytes,
    required String notes,
  }) async {
    final match = tasks.firstWhere((t) => t.id == taskId);
    final updated = match.copyWith(
      status: ReportStatus.resolved,
      resolutionNotes: notes,
    );
    return Success(updated);
  }
}

final testStaff = UserEntity(
  id: 'staff-map-1',
  name: 'Mario Limpieza',
  email: 'mario@ecoroute.com',
  role: UserRole.staff,
  createdAt: DateTime(2025, 1, 1),
);

void main() {
  testWidgets('Renderiza StaffRouteMapScreen con cabecera, circuito y paradas',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRepo = MockStaffRepository();

    final mockLoc = MockStaffLocationService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockStaffAuthViewModel(testStaff)),
          staffRepositoryProvider.overrideWithValue(mockRepo),
          locationServiceProvider.overrideWithValue(mockLoc),
        ],
        child: const MaterialApp(
          home: StaffRouteMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Título en AppBar
    expect(find.text('Mapa Operativo de Ruta'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    // 2. Franja flotante de circuito de recolección
    expect(find.text('Circuito de Recolección'), findsOneWidget);
    expect(find.textContaining('paradas'), findsWidgets);

    // 3. Botón flotante de GPS / Recentrado
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

    // 4. Barra de navegación inferior
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Tareas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('El mapa conserva todas las paradas al avanzar una ruta de equipo', (tester) async {
    final updates = StreamController<List<CollectionRoute>>();
    var externalLaunches = 0;
    addTearDown(updates.close);
    const stops = [
      CollectionStop(
        reportId: '1', number: '#1', address: 'Primera calle',
        location: LatLng(-7.1644, -78.5105), priority: ReportPriority.high,
      ),
      CollectionStop(
        reportId: '2', number: '#2', address: 'Segunda calle',
        location: LatLng(-7.1634, -78.5115), priority: ReportPriority.medium,
      ),
    ];
    CollectionRoute assigned(
      int progress, {
      String id = 'ruta',
      CollectionRouteStatus status = CollectionRouteStatus.inProgress,
    }) => CollectionRoute(
      id: id, name: 'Ruta Central', zone: CajamarcaZone.central,
      crewId: 'cuadrilla-2', crewName: 'Equipo 2', vehicle: 'Unidad 2',
      window: RouteWindow(DateTime(2026, 1, 1), DateTime(2026, 1, 2)),
      stops: stops, completedStops: progress, status: status,
      geometry: [for (final stop in stops) stop.location],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockStaffAuthViewModel(testStaff)),
          staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
          locationServiceProvider.overrideWithValue(MockStaffLocationService()),
          staffTeamIdProvider.overrideWith((ref) => Stream.value('cuadrilla-2')),
          collectionRoutesProvider('cuadrilla-2').overrideWith((ref) => updates.stream),
          collectionRouteProvider('ruta').overrideWith((ref) => Stream.value(assigned(1))),
          staffNavigationLauncherProvider.overrideWithValue((_) async {
            externalLaunches++;
            return true;
          }),
        ],
        child: const MaterialApp(home: StaffRouteMapScreen()),
      ),
    );
    final planned = assigned(0, id: 'planificada', status: CollectionRouteStatus.planned);
    final completed = assigned(2, id: 'terminada', status: CollectionRouteStatus.completed);
    final cancelled = assigned(0, id: 'cancelada', status: CollectionRouteStatus.cancelled);
    updates.add([assigned(0), planned, completed, cancelled]);
    await tester.pumpAndSettle();
    expect(find.text('Ruta Central'), findsOneWidget);
    expect(find.text('Siguiente parada 1 · Primera calle'), findsOneWidget);
    expect(find.text('Rutas'), findsOneWidget);
    Finder routeBadge(String value) => find.descendant(
      of: find.byType(StaffBottomNavBar),
      matching: find.text(value),
    );
    expect(routeBadge('2'), findsOneWidget);

    updates.add([assigned(1)]);
    await tester.pumpAndSettle();
    expect(routeBadge('1'), findsOneWidget);
    final map = tester.widget<CollectionRouteMap>(find.byType(CollectionRouteMap));
    expect(map.stops, stops);
    expect(map.nextStopIndex, 1);
    expect(find.text('Siguiente parada 2 · Segunda calle'), findsOneWidget);
    await tester.tap(find.byTooltip('Ir a la siguiente parada'));
    await tester.pumpAndSettle();
    expect(tester.widget<CollectionRouteMap>(find.byType(CollectionRouteMap)).focus, stops[1].location);
    await tester.tap(find.byTooltip('Ver recorrido completo'));
    await tester.pumpAndSettle();
    expect(tester.widget<CollectionRouteMap>(find.byType(CollectionRouteMap)).focus, isNull);

    await tester.tap(find.text('Continuar ruta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir a la siguiente parada'));
    await tester.pumpAndSettle();
    expect(tester.widget<CollectionRouteMap>(find.byType(CollectionRouteMap)).focus, stops[1].location);
    expect(externalLaunches, 0);

    updates.add([completed, cancelled]);
    await tester.pumpAndSettle();
    expect(routeBadge('1'), findsNothing);
  });

  testWidgets('Marcador de parada en el mapa se renderiza sin overflow de pixeles',
      (tester) async {
    // Probar el contenedor exacto del marcador con tamaño ajustado (80x72)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 80,
              height: 72,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Parada 1',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 40,
                          color: Color(0xFF047857),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Parada 1'), findsOneWidget);
  });

  testWidgets(
      'Iniciar tarea desde el mapa pide confirmación y al aceptar muestra solo la ruta de esa tarea ocultando las demás',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRepo = MockStaffRepository()
      ..tasks = [
        for (final (id, number, category, longitude) in [
          ('task-1', '#0102', 'Contenedor lleno', -78.5002),
          ('task-2', '#0103', 'Residuos en vía pública', -78.5160),
        ])
          StaffTaskEntity(
            id: id,
            reportNumber: number,
            teamId: 'norte',
            citizenId: 'citizen-1',
            citizenName: 'Vecino',
            categoryName: category,
            categoryIcon: 'delete_outline_rounded',
            description: category,
            priority: ReportPriority.medium,
            status: ReportStatus.pending,
            address: 'Cajamarca',
            reportImageUrls: const [],
            latitude: -7.1638,
            longitude: longitude,
            assignedAt: DateTime(2025, 1, 1),
          ),
      ];
    final mockLoc = MockStaffLocationService();
    final crew = StreamController<StaffCrew?>.broadcast();
    addTearDown(crew.close);
    final crewChanges = StreamProvider<StaffCrew?>((ref) => crew.stream);
    Uri? opened;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockStaffAuthViewModel(testStaff)),
          staffRepositoryProvider.overrideWithValue(mockRepo),
          locationServiceProvider.overrideWithValue(mockLoc),
          staffCrewProvider.overrideWith((ref) => ref.watch(crewChanges)),
          staffNavigationLauncherProvider.overrideWithValue((uri) async {
            opened = uri;
            return true;
          }),
        ],
        child: const MaterialApp(
          home: StaffRouteMapScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Inicialmente se muestran múltiples paradas pendientes y ninguna ruta activa
    expect(find.text('#0102 • Contenedor lleno'), findsOneWidget);
    expect(find.text('#0103 • Residuos en vía pública'), findsOneWidget);
    expect(find.text('Ruta aproximada'), findsNothing);

    // 2. Tocar una parada pendiente en el mapa abre su tarjeta inferior sin activar ruta aún
    await tester.tap(find.text('#0102 • Contenedor lleno'));
    await tester.pumpAndSettle();
    crew.add(StaffCrew(id: 'norte', leaderId: testStaff.id));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Ruta aproximada'), findsNothing);
    expect(find.text('#0103 • Residuos en vía pública'), findsOneWidget);

    // 3. Presionar "Iniciar" desde la tarjeta del mapa muestra el diálogo de confirmación
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar atención de tarea'), findsOneWidget);
    expect(find.text('¿Está seguro de que desea iniciar esta tarea?'), findsOneWidget);
    crew.add(const StaffCrew(id: 'norte', leaderId: 'nuevo-lider'));
    await tester.pumpAndSettle();
    expect(find.text('Sí, iniciar'), findsNothing);
    crew.add(StaffCrew(id: 'norte', leaderId: testStaff.id));
    await tester.pumpAndSettle();

    // 4. Si cancela, no inicia la ruta y mantiene todas las paradas visibles
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Ruta aproximada'), findsNothing);
    expect(find.text('#0103 • Residuos en vía pública'), findsOneWidget);

    // 5. Presionar "Iniciar" y confirmar "Sí, iniciar" activa la ruta y limpia las demás paradas
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, iniciar'));
    await tester.pumpAndSettle();

    expect(find.text('Ruta hacia #0102'), findsOneWidget);
    expect(find.text('Ruta aproximada'), findsOneWidget);
    expect(find.text('#0103 • Residuos en vía pública'), findsNothing);
    expect(find.text('Completar con evidencia'), findsOneWidget);
    crew.add(const StaffCrew(id: 'norte', leaderId: 'nuevo-lider'));
    await tester.pumpAndSettle();
    expect(find.text('Completar con evidencia'), findsNothing);
    expect(find.text('Ver detalle'), findsOneWidget);
    expect(find.text('Ruta hacia #0102'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StaffRouteMapScreen)),
    );
    expect(
      container.read(staffHomeViewModelProvider).activeRoute?.points.length,
      greaterThan(1),
    );
    await tester.tap(find.byTooltip('Abrir en Google Maps'));
    await tester.pumpAndSettle();
    expect(opened?.host, 'www.google.com');
    expect(opened?.queryParameters['destination'], '-7.1638,-78.5002');
  });
}

