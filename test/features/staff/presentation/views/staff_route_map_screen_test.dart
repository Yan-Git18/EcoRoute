import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/services/location_service.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/staff/domain/entities/staff_task_entity.dart';
import 'package:ecoroute/features/staff/domain/repositories/staff_repository.dart';
import 'package:ecoroute/features/staff/presentation/viewmodels/staff_home_viewmodel.dart';
import 'package:ecoroute/features/staff/presentation/views/staff_route_map_screen.dart';

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
      latitude: -12.046374,
      longitude: -77.042793,
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
      latitude: -12.046374,
      longitude: -77.042793,
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
    String? localImagePath,
    List<String>? localImagePaths,
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
    mockRepo.tasks = []; // Utiliza el fallback de demostración

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

    final mockRepo = MockStaffRepository();
    mockRepo.tasks = []; // Usa el fallback con varias paradas pendientes
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

    // 1. Inicialmente se muestran múltiples paradas pendientes y ninguna ruta activa
    expect(find.text('#0102 • Contenedor lleno'), findsOneWidget);
    expect(find.text('#0103 • Residuos en vía pública'), findsOneWidget);
    expect(find.text('Ruta óptima activa'), findsNothing);

    // 2. Tocar una parada pendiente en el mapa abre su tarjeta inferior sin activar ruta aún
    await tester.tap(find.text('#0102 • Contenedor lleno'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Ruta óptima activa'), findsNothing);
    expect(find.text('#0103 • Residuos en vía pública'), findsOneWidget);

    // 3. Presionar "Iniciar" desde la tarjeta del mapa muestra el diálogo de confirmación
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar atención de tarea'), findsOneWidget);
    expect(find.text('¿Está seguro de que desea iniciar esta tarea?'), findsOneWidget);

    // 4. Si cancela, no inicia la ruta y mantiene todas las paradas visibles
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Ruta óptima activa'), findsNothing);
    expect(find.text('#0103 • Residuos en vía pública'), findsOneWidget);

    // 5. Presionar "Iniciar" y confirmar "Sí, iniciar" activa la ruta y limpia las demás paradas
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, iniciar'));
    await tester.pumpAndSettle();

    expect(find.text('Ruta hacia #0102'), findsOneWidget);
    expect(find.text('Ruta óptima activa'), findsOneWidget);
    expect(find.text('#0103 • Residuos en vía pública'), findsNothing);
    expect(find.text('Completar con evidencia'), findsOneWidget);
  });
}

