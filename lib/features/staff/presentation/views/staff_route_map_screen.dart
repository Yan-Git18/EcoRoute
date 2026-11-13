import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../../core/constants/geo_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/route_navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/map/map_widgets.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../data/fixtures/staff_tasks_fixtures.dart';
import '../../domain/entities/staff_task_entity.dart';
import '../viewmodels/staff_home_viewmodel.dart';
import '../widgets/staff_bottom_nav_bar.dart';
import '../widgets/staff_complete_task_sheet.dart';
import '../widgets/staff_start_task_confirm_dialog.dart';
import '../widgets/staff_task_detail_sheet.dart';

/// Pantalla del Mapa Operativo de Rutas para la Cuadrilla de Limpieza (Fase 2).
///
/// Soporta dos modos operativos integrados:
/// 1. **Modo Navegación de Tarea Activa**: Cuando el trabajador confirma «Sí, iniciar»
///    en una tarea, muestra el mapa centrado en la ruta óptima entre la ubicación GPS
///    actual del trabajador y las coordenadas reales del reporte, con línea de recorrido,
///    marcador de origen («Tu ubicación»), marcador de destino, distancia, tiempo estimado
///    de llegada (ETA) e identificación completa del reporte atendido.
/// 2. **Modo Circuito de Recolección**: Vista general de todas las paradas pendientes y
///    en progreso asignadas al personal.
///
/// Ubicación: `lib/features/staff/presentation/views/staff_route_map_screen.dart`
/// Capa: Presentation (Personal)
class StaffRouteMapScreen extends ConsumerStatefulWidget {
  const StaffRouteMapScreen({super.key});

  @override
  ConsumerState<StaffRouteMapScreen> createState() => _StaffRouteMapScreenState();
}

class _StaffRouteMapScreenState extends ConsumerState<StaffRouteMapScreen> {
  final MapController _mapController = MapController();
  final TransformationController _desktopTransformController = TransformationController();

  double _userLat = AppGeoConstants.cajamarcaCenterLat;
  double _userLng = AppGeoConstants.cajamarcaCenterLng;
  bool _isLocating = false;
  StaffTaskEntity? _selectedTask;
  bool _isActiveCardDismissed = false;

  static List<StaffTaskEntity> get _defaultDemoTasks => StaffTasksFixtures.defaultDemoTasks;

  bool get _isFlutterTest {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMapState();
    });
  }

  Future<void> _initializeMapState() async {
    if (!mounted) return;
    final staffState = ref.read(staffHomeViewModelProvider);

    if (staffState.workerLatitude != null && staffState.workerLongitude != null) {
      setState(() {
        _userLat = staffState.workerLatitude!;
        _userLng = staffState.workerLongitude!;
        if (staffState.activeNavigationTask != null) {
          _selectedTask = staffState.activeNavigationTask;
        }
      });
      if (staffState.activeNavigationTask != null) {
        _centerCameraOnRoute(
          origin: LatLng(_userLat, _userLng),
          destination: LatLng(
            staffState.activeNavigationTask!.latitude,
            staffState.activeNavigationTask!.longitude,
          ),
          distanceMeters: staffState.activeRoute?.distanceMeters,
        );
      }
    } else {
      await _requestCurrentLocation();
      if (!mounted) return;
      final latestState = ref.read(staffHomeViewModelProvider);
      if (latestState.activeNavigationTask != null) {
        setState(() {
          _selectedTask = latestState.activeNavigationTask;
        });
      } else {
        // Si ya existe una tarea "En proceso" y el trabajador abre el mapa,
        // calcular automáticamente su ruta por calles
        final inProgressTasks = latestState.tasks.where((t) => t.isInProgress).toList();
        if (inProgressTasks.isNotEmpty) {
          final targetTask = inProgressTasks.first;
          await ref.read(staffHomeViewModelProvider.notifier).focusTaskRouteOnMap(targetTask);
          if (mounted) {
            setState(() => _selectedTask = targetTask);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _desktopTransformController.dispose();
    super.dispose();
  }

  Future<void> _requestCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final locService = ref.read(locationServiceProvider);
      final result = await locService.getCurrentPosition();
      if (mounted) {
        setState(() {
          if (result.latitude != 0.0 && result.longitude != 0.0) {
            _userLat = result.latitude;
            _userLng = result.longitude;
          } else {
            _userLat = AppGeoConstants.cajamarcaCenterLat;
            _userLng = AppGeoConstants.cajamarcaCenterLng;
          }
          _isLocating = false;
        });

        final activeTask = ref.read(staffHomeViewModelProvider).activeNavigationTask;
        if (activeTask != null) {
          await ref.read(staffHomeViewModelProvider.notifier).focusTaskRouteOnMap(activeTask);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _centerCameraOnRoute({
    required LatLng origin,
    required LatLng destination,
    double? distanceMeters,
  }) {
    if (_isFlutterTest) return;
    try {
      final midLat = (origin.latitude + destination.latitude) / 2;
      final midLng = (origin.longitude + destination.longitude) / 2;
      final dist = distanceMeters ??
          _computeDistanceMeters(
            origin.latitude,
            origin.longitude,
            destination.latitude,
            destination.longitude,
          );
      final zoom = _calculateRouteZoom(dist);
      _mapController.move(LatLng(midLat, midLng), zoom);
    } catch (_) {
      // Ignorar si el controlador aún no está montado en el widget tree
    }
  }

  double _calculateRouteZoom(double distanceMeters) {
    if (distanceMeters < 400) return 16.5;
    if (distanceMeters < 1000) return 15.5;
    if (distanceMeters < 2500) return 14.5;
    if (distanceMeters < 6000) return 13.5;
    return 12.5;
  }

  void _recenterMap() {
    final staffState = ref.read(staffHomeViewModelProvider);
    final activeTask = staffState.activeNavigationTask ?? _selectedTask;
    if (!_isFlutterTest) {
      if (activeTask != null) {
        _centerCameraOnRoute(
          origin: LatLng(_userLat, _userLng),
          destination: LatLng(activeTask.latitude, activeTask.longitude),
          distanceMeters: staffState.activeRoute?.distanceMeters,
        );
      } else {
        final target = (_userLat != 0.0 && _userLng != 0.0)
            ? LatLng(_userLat, _userLng)
            : AppGeoConstants.cajamarcaCenter;
        _mapController.move(target, AppGeoConstants.defaultZoom);
      }
    } else {
      _desktopTransformController.value = Matrix4.identity();
    }
  }

  void _zoomIn() {
    if (!_isFlutterTest) {
      final zoom = _mapController.camera.zoom;
      if (zoom < AppGeoConstants.maxZoom) {
        _mapController.move(_mapController.camera.center, zoom + 1.0);
      }
    }
  }

  void _zoomOut() {
    if (!_isFlutterTest) {
      final zoom = _mapController.camera.zoom;
      if (zoom > AppGeoConstants.minZoom) {
        _mapController.move(_mapController.camera.center, zoom - 1.0);
      }
    }
  }

  double _computeDistanceMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    try {
      return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    } catch (_) {
      const earthRadiusMeters = 6371000.0;
      final dLat = (endLat - startLat) * (math.pi / 180.0);
      final dLng = (endLng - startLng) * (math.pi / 180.0);
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(startLat * (math.pi / 180.0)) *
              math.cos(endLat * (math.pi / 180.0)) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      return earthRadiusMeters * c;
    }
  }

  String _formatDistanceTo(double targetLat, double targetLng) {
    final meters = _computeDistanceMeters(_userLat, _userLng, targetLat, targetLng);
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatEstimatedTimeTo(double targetLat, double targetLng) {
    final meters = _computeDistanceMeters(_userLat, _userLng, targetLat, targetLng);
    if (meters < 15) return '< 1 min';
    final minutes = math.max(1, (meters / 6.94 / 60).ceil());
    if (minutes < 60) return '~$minutes min';
    return '${minutes ~/ 60} h ${minutes % 60} min';
  }

  Future<void> _handleConfirmAndStartTask(StaffTaskEntity task) async {
    final currentActive = ref.read(staffHomeViewModelProvider).currentInProgressTask;
    if (currentActive != null && currentActive.id != task.id) {
      final goToMap = await StaffStartTaskConfirmDialog.showActiveTaskConflictDialog(
        context,
        activeTask: currentActive,
      );
      if (!goToMap || !mounted) return;
      await ref.read(staffHomeViewModelProvider.notifier).focusTaskRouteOnMap(currentActive);
      if (!mounted) return;
      setState(() {
        _selectedTask = currentActive;
        _isActiveCardDismissed = false;
      });
      return;
    }

    final confirmed = await StaffStartTaskConfirmDialog.show(
      context,
      task: task,
    );
    if (!confirmed || !mounted) return;

    final viewModel = ref.read(staffHomeViewModelProvider.notifier);
    final success = await viewModel.startTaskWithNavigation(task);
    if (!mounted || !success) return;

    final updatedState = ref.read(staffHomeViewModelProvider);
    setState(() {
      if (updatedState.workerLatitude != null && updatedState.workerLongitude != null) {
        _userLat = updatedState.workerLatitude!;
        _userLng = updatedState.workerLongitude!;
      }
      _selectedTask = updatedState.activeNavigationTask ??
          task.copyWith(status: ReportStatus.inProgress);
      _isActiveCardDismissed = false;
    });

    if (updatedState.activeNavigationTask != null) {
      _centerCameraOnRoute(
        origin: LatLng(_userLat, _userLng),
        destination: LatLng(
          updatedState.activeNavigationTask!.latitude,
          updatedState.activeNavigationTask!.longitude,
        ),
        distanceMeters: updatedState.activeRoute?.distanceMeters,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffHomeViewModelProvider);
    final viewModel = ref.read(staffHomeViewModelProvider.notifier);

    final tasks = staffState.tasks.isNotEmpty ? staffState.tasks : _defaultDemoTasks;
    final activeTasks = tasks.where((t) => !t.isResolved).toList();

    // Solo se considera tarea en navegación activa aquella que ya está iniciada ("En proceso")
    final activeNavTask = staffState.currentInProgressTask;
    final activeRoute = activeNavTask != null ? staffState.activeRoute : null;
    final effectiveSelectedTask = activeNavTask != null
        ? (_isActiveCardDismissed ? null : activeNavTask)
        : _selectedTask;

    final workerLat = staffState.workerLatitude ?? _userLat;
    final workerLng = staffState.workerLongitude ?? _userLng;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (GoRouter.maybeOf(context) != null) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.staffHome);
              }
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeNavTask != null
                  ? 'Ruta hacia ${activeNavTask.reportNumber}'
                  : 'Mapa Operativo de Ruta',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              activeNavTask != null
                  ? 'Atendiendo: ${activeNavTask.categoryName}'
                  : '${activeTasks.length} paradas pendientes en el circuito',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF047857),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Actualizar ruta',
            onPressed: () {
              viewModel.refresh();
              _requestCurrentLocation();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // 1. Capa de Mapa Real con OpenStreetMap o fallback de test
          Positioned.fill(
            child: _isFlutterTest
                ? _buildTestVectorMap(
                    activeTasks: activeTasks,
                    activeNavTask: activeNavTask,
                    activeRoute: activeRoute,
                    workerLat: workerLat,
                    workerLng: workerLng,
                  )
                : _buildOpenStreetMap(
                    activeTasks: activeTasks,
                    activeNavTask: activeNavTask,
                    activeRoute: activeRoute,
                    workerLat: workerLat,
                    workerLng: workerLng,
                  ),
          ),

          // 2. Franja de Estado Superior Flotante (Ruta Activa o Circuito de Recolección)
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: activeNavTask != null
                  ? _ActiveRouteHeaderBanner(
                      task: activeNavTask,
                      distanceText: activeRoute?.formattedDistance ??
                          _formatDistanceTo(activeNavTask.latitude, activeNavTask.longitude),
                      durationText: activeRoute?.formattedDuration ??
                          _formatEstimatedTimeTo(activeNavTask.latitude, activeNavTask.longitude),
                    )
                  : _CircuitHeaderBanner(activeTasksCount: activeTasks.length),
            ),
          ),

          // 3. Controles de Zoom vertical flotantes en la esquina superior derecha
          Positioned(
            top: activeNavTask != null ? 116 : 86,
            right: 16,
            child: Column(
              children: [
                MapControlButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Acercar mapa',
                  onPressed: _zoomIn,
                ),
                const SizedBox(height: 6),
                MapControlButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Alejar mapa',
                  onPressed: _zoomOut,
                ),
              ],
            ),
          ),

          // 4. Botón flotante para recentrar en la ruta / ubicación actual
          Positioned(
            bottom: effectiveSelectedTask != null ? 235 : 20,
            right: 16,
            child: _FloatingLocationButton(
              isLocating: _isLocating,
              onPressed: () {
                _requestCurrentLocation();
                _recenterMap();
              },
            ),
          ),

          // 5. Tarjeta emergente flotante con la parada/incidencia seleccionada o en atención
          if (effectiveSelectedTask != null)
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                offset: Offset.zero,
                curve: Curves.easeOutCubic,
                child: _StaffTaskMapPreviewCard(
                  task: effectiveSelectedTask,
                  formattedDistance: (activeNavTask?.id == effectiveSelectedTask.id &&
                          activeRoute != null)
                      ? activeRoute.formattedDistance
                      : _formatDistanceTo(
                          effectiveSelectedTask.latitude,
                          effectiveSelectedTask.longitude,
                        ),
                  formattedDuration: (activeNavTask?.id == effectiveSelectedTask.id &&
                          activeRoute != null)
                      ? activeRoute.formattedDuration
                      : _formatEstimatedTimeTo(
                          effectiveSelectedTask.latitude,
                          effectiveSelectedTask.longitude,
                        ),
                  onClose: () {
                    setState(() {
                      if (activeNavTask != null) {
                        _isActiveCardDismissed = true;
                      } else {
                        _selectedTask = null;
                      }
                    });
                  },
                  onStart: () => _handleConfirmAndStartTask(effectiveSelectedTask),
                  onResolve: () {
                    StaffCompleteTaskSheet.show(context, effectiveSelectedTask);
                  },
                  onViewDetail: () {
                    StaffTaskDetailSheet.show(
                      context: context,
                      task: effectiveSelectedTask,
                      onStart: () => _handleConfirmAndStartTask(effectiveSelectedTask),
                      onResolve: () => StaffCompleteTaskSheet.show(context, effectiveSelectedTask),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: 1,
        onTabSelected: (index) {
          if (index == 0) {
            context.go(RouteNames.staffHome);
          } else if (index == 1) {
            // Ya en mapa
          } else if (index == 2) {
            context.go(RouteNames.staffTasks);
          } else if (index == 3) {
            context.push(RouteNames.staffProfile);
          }
        },
      ),
    );
  }

  // --- Mapa real con flutter_map y OpenStreetMap ---

  Widget _buildOpenStreetMap({
    required List<StaffTaskEntity> activeTasks,
    required StaffTaskEntity? activeNavTask,
    required RouteInfoResult? activeRoute,
    required double workerLat,
    required double workerLng,
  }) {
    final validUserPos = (workerLat != 0.0 && workerLng != 0.0)
        ? LatLng(workerLat, workerLng)
        : AppGeoConstants.cajamarcaCenter;

    // Si hay una tarea activa en navegación, centrar la vista en la ruta hacia el reporte
    LatLng initialCenter = validUserPos;
    double initialZoom = AppGeoConstants.defaultZoom;

    if (activeNavTask != null &&
        activeNavTask.latitude != 0.0 &&
        activeNavTask.longitude != 0.0) {
      initialCenter = LatLng(
        (validUserPos.latitude + activeNavTask.latitude) / 2,
        (validUserPos.longitude + activeNavTask.longitude) / 2,
      );
      final dist = activeRoute?.distanceMeters ??
          _computeDistanceMeters(
            validUserPos.latitude,
            validUserPos.longitude,
            activeNavTask.latitude,
            activeNavTask.longitude,
          );
      initialZoom = _calculateRouteZoom(dist);
    }

    // Construir puntos de la ruta vial por calles (evitando líneas rectas entre todos los pines)
    final List<LatLng> routePoints;
    if (activeRoute != null && activeRoute.points.length >= 2) {
      routePoints = activeRoute.points;
    } else if (activeNavTask != null &&
        activeNavTask.latitude != 0.0 &&
        activeNavTask.longitude != 0.0) {
      routePoints = [
        validUserPos,
        LatLng(activeNavTask.latitude, activeNavTask.longitude),
      ];
    } else {
      routePoints = const <LatLng>[];
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        minZoom: 5.0,
        maxZoom: AppGeoConstants.maxZoom,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        onTap: (_, __) {
          if (activeNavTask == null) {
            setState(() => _selectedTask = null);
          }
        },
      ),
      children: [
        // 1. Capa de teselas OpenStreetMap gratuita
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ecoroute',
          maxZoom: 19,
        ),

        // 2. Línea de recorrido que indica la ruta recomendada
        if (routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: activeNavTask != null
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF047857).withAlpha(190),
                strokeWidth: activeNavTask != null ? 5.5 : 4.5,
                borderColor: Colors.white,
                borderStrokeWidth: 2.0,
              ),
            ],
          ),

        // 3. Marcadores de ubicación actual del trabajador y destino(s)
        MarkerLayer(
          markers: [
            // Marcador GPS de la ubicación actual del trabajador
            Marker(
              point: validUserPos,
              width: 96,
              height: 68,
              alignment: Alignment.center,
              child: const _StaffTruckMarker(showLabel: true),
            ),

            // Si hay una tarea en navegación activa, destacar el marcador de destino del reporte
            if (activeNavTask != null)
              _buildStopMarker(
                activeNavTask,
                stopNumber: 1,
                isDestinationTarget: true,
              )
            else
              for (int i = 0; i < activeTasks.length; i++)
                _buildStopMarker(activeTasks[i], stopNumber: i + 1),
          ],
        ),
      ],
    );
  }

  Marker _buildStopMarker(
    StaffTaskEntity task, {
    required int stopNumber,
    bool isDestinationTarget = false,
  }) {
    final isSelected = isDestinationTarget || _selectedTask?.id == task.id;
    final pinColor = _getTaskPinColor(task);

    return Marker(
      point: LatLng(task.latitude, task.longitude),
      width: isSelected ? 105 : 80,
      height: isSelected ? 84 : 72,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedTask = task;
            _isActiveCardDismissed = false;
          });
          if (task.isInProgress) {
            ref.read(staffHomeViewModelProvider.notifier).focusTaskRouteOnMap(task);
          }
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedScale(
            scale: isSelected ? 1.12 : 1.0,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Badge de destino o parada
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : pinColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    isDestinationTarget
                        ? 'Destino ${task.reportNumber}'
                        : (isSelected ? task.reportNumber : 'Parada $stopNumber'),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),

                // Pin con icono
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: isSelected ? 46 : 40,
                      color: pinColor,
                      shadows: [
                        BoxShadow(
                          color: pinColor.withAlpha(120),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    Positioned(
                      top: isSelected ? 8 : 7,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isDestinationTarget
                              ? Icon(Icons.flag_rounded, size: 10, color: pinColor)
                              : Text(
                                  '$stopNumber',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: pinColor,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTaskPinColor(StaffTaskEntity task) {
    if (task.isInProgress) return AppColors.statusInProgress;
    if (task.isResolved) return AppColors.statusResolved;
    switch (task.priority) {
      case ReportPriority.high:
        return const Color(0xFFEF4444); // Rojo prioridad alta
      case ReportPriority.medium:
        return const Color(0xFFF59E0B); // Ámbar prioridad media
      case ReportPriority.low:
        return const Color(0xFF10B981); // Verde prioridad baja
    }
  }

  // --- Respaldo Vectorial para Pruebas Automatizadas (flutter test) ---

  Widget _buildTestVectorMap({
    required List<StaffTaskEntity> activeTasks,
    required StaffTaskEntity? activeNavTask,
    required RouteInfoResult? activeRoute,
    required double workerLat,
    required double workerLng,
  }) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_rounded, size: 54, color: Color(0xFF047857)),
              const SizedBox(height: 12),
              if (activeNavTask != null) ...[
                const Text(
                  'Ruta óptima activa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Origen trabajador: (${workerLat.toStringAsFixed(4)}, ${workerLng.toStringAsFixed(4)})',
                ),
                Text(
                  'Destino reporte ${activeNavTask.reportNumber}: (${activeNavTask.latitude.toStringAsFixed(4)}, ${activeNavTask.longitude.toStringAsFixed(4)})',
                ),
                if (activeRoute != null)
                  Text(
                    'Distancia: ${activeRoute.formattedDistance} • Tiempo estimado: ${activeRoute.formattedDuration}',
                  ),
              ] else ...[
                Text(
                  'Mapa Operativo: ${activeTasks.length} paradas activas',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                for (final t in activeTasks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: InkWell(
                      onTap: () => setState(() => _selectedTask = t),
                      child: Text('${t.reportNumber} • ${t.categoryName}'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner superior cuando el trabajador está navegando hacia una tarea específica.
class _ActiveRouteHeaderBanner extends StatelessWidget {
  final StaffTaskEntity task;
  final String distanceText;
  final String durationText;

  const _ActiveRouteHeaderBanner({
    required this.task,
    required this.distanceText,
    required this.durationText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(248),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'En ruta a ${task.reportNumber} • ${task.categoryName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      task.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.straighten_rounded, size: 13, color: Color(0xFF047857)),
                    const SizedBox(width: 4),
                    Text(
                      'Distancia: $distanceText',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 4),
                    Text(
                      'Llegada: $durationText',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Banner superior cuando se visualiza el circuito general de paradas.
class _CircuitHeaderBanner extends StatelessWidget {
  final int activeTasksCount;

  const _CircuitHeaderBanner({required this.activeTasksCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(240),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A5835).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_rounded,
              color: Color(0xFF0A5835),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Circuito de Recolección',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  activeTasksCount == 0
                      ? 'Todas las paradas en Cajamarca han sido atendidas.'
                      : 'Ruta urbana activa en Cajamarca.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$activeTasksCount paradas',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF047857),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marcador estilizado de la ubicación actual del trabajador / unidad de recolección.
class _StaffTruckMarker extends StatelessWidget {
  final bool showLabel;

  const _StaffTruckMarker({this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0A5835),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Text(
              'Tu ubicación',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF047857).withAlpha(40),
                border: Border.all(
                  color: const Color(0xFF047857).withAlpha(120),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A5835),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Botón flotante para recentrar en ubicación actual
class _FloatingLocationButton extends StatelessWidget {
  final bool isLocating;
  final VoidCallback onPressed;

  const _FloatingLocationButton({
    required this.isLocating,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: isLocating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF0A5835),
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    size: 24,
                    color: Color(0xFF0A5835),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta flotante emergente para visualizar la tarea atendida, distancia, ETA y acciones.
class _StaffTaskMapPreviewCard extends StatelessWidget {
  final StaffTaskEntity task;
  final String formattedDistance;
  final String formattedDuration;
  final VoidCallback onClose;
  final VoidCallback onStart;
  final VoidCallback onResolve;
  final VoidCallback onViewDetail;

  const _StaffTaskMapPreviewCard({
    required this.task,
    required this.formattedDistance,
    required this.formattedDuration,
    required this.onClose,
    required this.onStart,
    required this.onResolve,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Folio, Estado, Prioridad y Botón Cerrar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.reportNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: task.isInProgress
                            ? const Color(0xFFDBEAFE)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.isInProgress ? 'En proceso' : 'Pendiente',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: task.isInProgress
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _PriorityBadge(priority: task.priority),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Título de categoría y dirección
            Text(
              task.categoryName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Distancia y tiempo estimado de llegada
            Row(
              children: [
                const Icon(Icons.route_rounded, size: 15, color: Color(0xFF047857)),
                const SizedBox(width: 4),
                Text(
                  formattedDistance,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF047857),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.schedule_rounded, size: 15, color: Color(0xFF2563EB)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Llegada est.: $formattedDuration',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Botones de acción según estado (Ver detalle + Iniciar / Completar)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onViewDetail,
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('Ver detalle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: task.isInProgress
                        ? ElevatedButton.icon(
                            onPressed: onResolve,
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: const Text('Completar con evidencia'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF047857),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: onStart,
                            icon: const Icon(Icons.play_arrow_rounded, size: 20),
                            label: const Text('Iniciar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final ReportPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (priority) {
      case ReportPriority.high:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'Alta';
        break;
      case ReportPriority.medium:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'Media';
        break;
      case ReportPriority.low:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        label = 'Baja';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
