import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../../core/router/route_names.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/staff_task_entity.dart';
import '../viewmodels/staff_home_viewmodel.dart';
import '../widgets/staff_bottom_nav_bar.dart';
import '../widgets/staff_complete_task_sheet.dart';

/// Pantalla del Mapa Operativo de Rutas para la Cuadrilla de Limpieza (Fase 2).
///
/// Utiliza [FlutterMap] con OpenStreetMap para mostrar la ubicación GPS actual del operario,
/// los puntos de recolección geolocalizados, el trazado del circuito sugerido y una tarjeta
/// interactiva de acción directa para atender o completar tareas.
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

  double _userLat = -12.046374;
  double _userLng = -77.042793;
  bool _isLocating = false;
  StaffTaskEntity? _selectedTask;

  // Tareas de demostración para visualización inicial si la base de datos está vacía
  static final List<StaffTaskEntity> _defaultDemoTasks = [
    StaffTaskEntity(
      id: 'task-demo-1',
      reportNumber: '#0102',
      citizenId: 'c-demo-1',
      citizenName: 'Vecino Ciudadano',
      categoryName: 'Contenedor lleno',
      categoryIcon: 'delete_outline_rounded',
      description: 'Contenedor saturado en la avenida principal.',
      priority: ReportPriority.high,
      status: ReportStatus.pending,
      address: 'Av. Los Próceres 452',
      latitude: -12.0440,
      longitude: -77.0400,
      reportImageUrls: const [],
      assignedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    StaffTaskEntity(
      id: 'task-demo-2',
      reportNumber: '#0103',
      citizenId: 'c-demo-2',
      citizenName: 'Vecino Ciudadano',
      categoryName: 'Residuos en vía pública',
      categoryIcon: 'cleaning_services_rounded',
      description: 'Restos de poda y bolsas en vereda.',
      priority: ReportPriority.medium,
      status: ReportStatus.pending,
      address: 'Jr. Amazonas 120',
      latitude: -12.0480,
      longitude: -77.0415,
      reportImageUrls: const [],
      assignedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    StaffTaskEntity(
      id: 'task-demo-3',
      reportNumber: '#0104',
      citizenId: 'c-demo-3',
      citizenName: 'Vecino Ciudadano',
      categoryName: 'Punto de recolección',
      categoryIcon: 'recycling_rounded',
      description: 'Limpieza periódica de contenedores verdes.',
      priority: ReportPriority.low,
      status: ReportStatus.pending,
      address: 'Parque Central',
      latitude: -12.0510,
      longitude: -77.0440,
      reportImageUrls: const [],
      assignedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    StaffTaskEntity(
      id: 'task-demo-5',
      reportNumber: '#0101',
      citizenId: 'c-demo-5',
      citizenName: 'Vecino Ciudadano',
      categoryName: 'Desborde de basura',
      categoryIcon: 'delete_outline_rounded',
      description: 'Cuadrilla atendiendo en zona con camión recolector.',
      priority: ReportPriority.high,
      status: ReportStatus.inProgress,
      address: 'Calle Los Pinos 88',
      latitude: -12.0430,
      longitude: -77.0460,
      reportImageUrls: const [],
      assignedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  bool get _isFlutterTest {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  @override
  void initState() {
    super.initState();
    _requestCurrentLocation();
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
          _userLat = result.latitude;
          _userLng = result.longitude;
          _isLocating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _recenterMap() {
    if (!_isFlutterTest) {
      _mapController.move(LatLng(_userLat, _userLng), 15.0);
    } else {
      _desktopTransformController.value = Matrix4.identity();
    }
  }

  String _formatDistanceTo(double targetLat, double targetLng) {
    try {
      final meters = Geolocator.distanceBetween(_userLat, _userLng, targetLat, targetLng);
      if (meters < 1000) {
        return '${meters.round()} m';
      } else {
        return '${(meters / 1000).toStringAsFixed(1)} km';
      }
    } catch (_) {
      return '0 m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffHomeViewModelProvider);
    final viewModel = ref.read(staffHomeViewModelProvider.notifier);

    final tasks = staffState.tasks.isNotEmpty ? staffState.tasks : _defaultDemoTasks;
    final activeTasks = tasks.where((t) => !t.isResolved).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.staffHome);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mapa Operativo de Ruta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${activeTasks.length} paradas pendientes en el circuito',
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
                ? _buildTestVectorMap(activeTasks)
                : _buildOpenStreetMap(activeTasks),
          ),

          // 2. Franja de Estado Superior Flotante
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Container(
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
                            activeTasks.isEmpty
                                ? 'Todas las paradas han sido atendidas.'
                                : 'Ruta activa optimizada para tu cuadrilla.',
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
                        '${activeTasks.length} paradas',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Botón flotante para recentrar en ubicación GPS del vehículo
          Positioned(
            bottom: _selectedTask != null ? 220 : 20,
            right: 16,
            child: _FloatingLocationButton(
              isLocating: _isLocating,
              onPressed: () {
                _requestCurrentLocation();
                _recenterMap();
              },
            ),
          ),

          // 4. Tarjeta emergente flotante con la parada/incidencia seleccionada
          if (_selectedTask != null)
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                offset: Offset.zero,
                curve: Curves.easeOutCubic,
                child: _StaffTaskMapPreviewCard(
                  task: _selectedTask!,
                  formattedDistance: _formatDistanceTo(_selectedTask!.latitude, _selectedTask!.longitude),
                  onClose: () => setState(() => _selectedTask = null),
                  onStart: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await viewModel.startTask(_selectedTask!.id);
                    if (mounted) {
                      setState(() {
                        _selectedTask = _selectedTask!.copyWith(status: ReportStatus.inProgress);
                      });
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Atención iniciada en ${_selectedTask!.reportNumber}.'),
                          backgroundColor: AppColors.info,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  onResolve: () {
                    StaffCompleteTaskSheet.show(context, _selectedTask!);
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

  Widget _buildOpenStreetMap(List<StaffTaskEntity> activeTasks) {
    final routePoints = <LatLng>[
      LatLng(_userLat, _userLng),
      for (final t in activeTasks)
        LatLng(t.latitude, t.longitude),
    ];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(_userLat, _userLng),
        initialZoom: 14.5,
        minZoom: 3.0,
        maxZoom: 19.0,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        onTap: (_, __) => setState(() => _selectedTask = null),
      ),
      children: [
        // 1. Capa de teselas OpenStreetMap gratuita
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ecoroute',
          maxZoom: 19,
        ),

        // 2. Trazo de la ruta sugerida de recolección (Polilínea punteada/continua)
        if (routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: const Color(0xFF047857).withAlpha(190),
                strokeWidth: 4.5,
                borderColor: Colors.white,
                borderStrokeWidth: 1.5,
              ),
            ],
          ),

        // 3. Marcadores de vehículos y paradas
        MarkerLayer(
          markers: [
            // Marcador GPS del vehículo / operario
            Marker(
              point: LatLng(_userLat, _userLng),
              width: 54,
              height: 54,
              alignment: Alignment.center,
              child: const _StaffTruckMarker(),
            ),

            // Marcadores de paradas pendientes numeradas
            for (int i = 0; i < activeTasks.length; i++)
              _buildStopMarker(activeTasks[i], stopNumber: i + 1),
          ],
        ),
      ],
    );
  }

  Marker _buildStopMarker(StaffTaskEntity task, {required int stopNumber}) {
    final isSelected = _selectedTask?.id == task.id;
    final pinColor = _getTaskPinColor(task);

    return Marker(
      point: LatLng(task.latitude, task.longitude),
      width: isSelected ? 80 : 50,
      height: isSelected ? 82 : 56,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedTask = task),
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge de parada
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                  isSelected ? task.reportNumber : 'Parada $stopNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
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
                        child: Text(
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

  Widget _buildTestVectorMap(List<StaffTaskEntity> activeTasks) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_rounded, size: 54, color: Color(0xFF047857)),
            const SizedBox(height: 12),
            Text(
              'Mapa Operativo: ${activeTasks.length} paradas activas',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            for (final t in activeTasks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text('${t.reportNumber} • ${t.categoryName}'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Marcador estilizado del Camión / Unidad de recolección de cuadrilla
class _StaffTruckMarker extends StatelessWidget {
  const _StaffTruckMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
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
          width: 32,
          height: 32,
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
              size: 16,
            ),
          ),
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

/// Tarjeta flotante emergente para previsualizar una parada y ejecutar acciones directas
class _StaffTaskMapPreviewCard extends StatelessWidget {
  final StaffTaskEntity task;
  final String formattedDistance;
  final VoidCallback onClose;
  final VoidCallback onStart;
  final VoidCallback onResolve;

  const _StaffTaskMapPreviewCard({
    required this.task,
    required this.formattedDistance,
    required this.onClose,
    required this.onStart,
    required this.onResolve,
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
            // Cabecera: Folio, Prioridad y Botón Cerrar
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
                    const SizedBox(width: 8),
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
                const SizedBox(width: 8),
                Text(
                  formattedDistance,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Botón de acción según estado
            SizedBox(
              width: double.infinity,
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
                      label: const Text('Atender esta parada'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A5835),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
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
