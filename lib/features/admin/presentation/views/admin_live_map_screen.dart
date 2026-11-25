import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../../core/constants/geo_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_assign_crew_modal.dart';
import '../widgets/admin_back_button.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/admin_load_notice.dart';
import '../widgets/admin_map_crew_preview_card.dart';
import '../widgets/admin_map_report_preview_card.dart';

/// Filtros para la visualización de capas en el mapa macro urbano.
enum AdminMapFilter {
  all('Todas'),
  urgent('Urgentes'),
  pending('Pendientes'),
  crews('Personal');

  final String label;
  const AdminMapFilter(this.label);
}

/// Pantalla del Mapa Macro de Monitoreo Urbano en Tiempo Real (Admin Fase 2).
///
/// Permite al Administrador Municipal supervisar la totalidad de incidencias
/// reportadas por la ciudadanía, ubicaciones de cuadrillas y despachar personal
/// directamente desde el mapa cartográfico interactivo (OpenStreetMap).
///
/// Ubicación: `lib/features/admin/presentation/views/admin_live_map_screen.dart`
/// Capa: Presentation (Administrador)
class AdminLiveMapScreen extends ConsumerStatefulWidget {
  const AdminLiveMapScreen({super.key, this.initialCrewId});

  final String? initialCrewId;

  @override
  ConsumerState<AdminLiveMapScreen> createState() => _AdminLiveMapScreenState();
}

class _AdminLiveMapScreenState extends ConsumerState<AdminLiveMapScreen> {
  final MapController _mapController = MapController();

  AdminMapFilter _activeFilter = AdminMapFilter.all;
  String? _selectedReportId;
  String? _selectedCrewId;
  bool _showLegend = false;

  @override
  void initState() {
    super.initState();
    _selectedCrewId = widget.initialCrewId;
    if (_selectedCrewId != null) _activeFilter = AdminMapFilter.crews;
  }

  // Centro urbano de referencia (Cajamarca / Municipalidad)
  static const double _cityCenterLat = AppGeoConstants.cajamarcaCenterLat;
  static const double _cityCenterLng = AppGeoConstants.cajamarcaCenterLng;

  bool get _isFlutterTest {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenterMap([double lat = _cityCenterLat, double lng = _cityCenterLng]) {
    try {
      _mapController.move(LatLng(lat, lng), 14.5);
    } catch (_) {}
  }

  List<ReportEntity> _getFilteredReports(List<ReportEntity> allReports) {
    switch (_activeFilter) {
      case AdminMapFilter.all:
        return allReports;
      case AdminMapFilter.urgent:
        return allReports.where((r) => r.priority == ReportPriority.high).toList();
      case AdminMapFilter.pending:
        return allReports.where((r) => r.status == ReportStatus.pending).toList();
      case AdminMapFilter.crews:
        return [];
    }
  }

  List<MunicipalCrewEntity> _getFilteredCrews(List<MunicipalCrewEntity> allCrews) {
    if (_activeFilter == AdminMapFilter.urgent || _activeFilter == AdminMapFilter.pending) {
      return [];
    }
    return allCrews.where((crew) => crew.hasLocation).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final adminUser = authState.user;
    final adminName = adminUser?.name ?? 'Administrador Municipal';
    final adminId = adminUser?.id ?? 'admin-root';

    final adminReportsState = ref.watch(adminReportsViewModelProvider);
    final viewModel = ref.read(adminReportsViewModelProvider.notifier);

    final reports = adminReportsState.reports;
    final crews = adminReportsState.teams;
    final hasReports = adminReportsState.hasLoadedReports;
    final hasCrews = adminReportsState.hasLoadedCrews;
    final selectedReport = reports.where((report) => report.id == _selectedReportId).firstOrNull;
    final selectedCrew = crews.where((crew) => crew.id == _selectedCrewId && crew.hasLocation).firstOrNull;
    final initialCrew = crews.where((crew) => crew.id == widget.initialCrewId && crew.hasLocation).firstOrNull;

    final visibleReports = _getFilteredReports(reports);
    final visibleCrews = _getFilteredCrews(crews);

    final urgentCount = reports.where((r) => r.priority == ReportPriority.high).length;
    final pendingCount = reports.where((r) => r.status == ReportStatus.pending).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AdminBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mapa de Monitoreo Urbano',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${hasReports ? reports.length : '—'} incidencias cargadas',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF047857),
              ),
            ),
          ],
        ),
        actions: [
          if (adminReportsState.nextCursor != null)
            IconButton(
              icon: const Icon(Icons.expand_more),
              tooltip: 'Cargar más incidencias en el mapa',
              onPressed: adminReportsState.isLoading || adminReportsState.isLoadingMore
                  ? null
                  : () async {
                      await viewModel.loadMoreReports();
                      if (context.mounted && ref.read(adminReportsViewModelProvider).loadMoreFailed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pudo cargar la página siguiente.')),
                        );
                      }
                    },
            ),
          IconButton(
            icon: Icon(
              _showLegend ? Icons.info_rounded : Icons.info_outline_rounded,
              color: _showLegend ? const Color(0xFF0A5835) : const Color(0xFF475569),
            ),
            tooltip: 'Leyenda del mapa',
            onPressed: () => setState(() => _showLegend = !_showLegend),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Actualizar mapa',
            onPressed: adminReportsState.isLoading ? null : viewModel.refresh,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          AdminLoadNotice(state: adminReportsState, onRetry: viewModel.refresh),
          if (adminReportsState.isLoadingMore)
            const LinearProgressIndicator(semanticsLabel: 'Cargando más incidencias'),
          if (hasReports || hasCrews)
            Expanded(
              child: Stack(
                children: [
                  // 1. Capa de Mapa Real con OpenStreetMap o fallback de test
                  Positioned.fill(
                    child: _isFlutterTest
                        ? _buildTestVectorMap(visibleReports, visibleCrews)
                        : _buildOpenStreetMap(visibleReports, visibleCrews, initialCrew),
                  ),

                  // 2. Barra Flotante de Filtros Rápidos (Chips)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _MapFilterChip(
                            label: 'Todos (${hasReports ? reports.length : '—'})',
                            isSelected: _activeFilter == AdminMapFilter.all,
                            onTap: () => setState(() => _activeFilter = AdminMapFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _MapFilterChip(
                            label: 'Urgentes (${hasReports ? urgentCount : '—'})',
                            isSelected: _activeFilter == AdminMapFilter.urgent,
                            color: const Color(0xFFDC2626),
                            icon: Icons.priority_high_rounded,
                            onTap: () => setState(() => _activeFilter = AdminMapFilter.urgent),
                          ),
                          const SizedBox(width: 8),
                          _MapFilterChip(
                            label: 'Pendientes (${hasReports ? pendingCount : '—'})',
                            isSelected: _activeFilter == AdminMapFilter.pending,
                            color: const Color(0xFFD97706),
                            icon: Icons.pending_actions_rounded,
                            onTap: () => setState(() => _activeFilter = AdminMapFilter.pending),
                          ),
                          const SizedBox(width: 8),
                          _MapFilterChip(
                            label: 'Personal (${hasCrews ? crews.length : '—'})',
                            isSelected: _activeFilter == AdminMapFilter.crews,
                            color: const Color(0xFF047857),
                            icon: Icons.local_shipping_rounded,
                            onTap: () => setState(() => _activeFilter = AdminMapFilter.crews),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Leyenda explicativa flotante
                  if (_showLegend)
                    Positioned(
                      top: 60,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(245),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 3)),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Leyenda de Monitoreo',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 6),
                            _LegendItem(color: Color(0xFFDC2626), label: 'Urgente / Alta'),
                            _LegendItem(color: Color(0xFFD97706), label: 'Media Prioridad'),
                            _LegendItem(color: Color(0xFF059669), label: 'Baja Prioridad'),
                            _LegendItem(color: Color(0xFF0A5835), label: 'Personal Activo (Camión)'),
                          ],
                        ),
                      ),
                    ),

                  // 4. Botón flotante para recentrar mapa
                  Positioned(
                    bottom: (selectedReport != null || selectedCrew != null) ? 260 : 20,
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'recenter_admin_map',
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0A5835),
                      elevation: 4,
                      onPressed: () => _recenterMap(),
                      child: const Icon(Icons.my_location_rounded, size: 20),
                    ),
                  ),

                  // 5. Tarjeta emergente para reporte seleccionado
                  if (selectedReport != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: AdminMapReportPreviewCard(
                        report: selectedReport,
                        onClose: () => setState(() => _selectedReportId = null),
                        onAssignCrew: () => _openAssignModal(
                          report: selectedReport,
                          adminId: adminId,
                          adminName: adminName,
                        ),
                      ),
                    ),

                  // 6. Tarjeta emergente para cuadrilla seleccionada
                  if (selectedCrew != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: AdminMapCrewPreviewCard(
                        crew: selectedCrew,
                        onClose: () => setState(() => _selectedCrewId = null),
                        onViewTasks: () {
                          context.push(RouteNames.adminReports);
                        },
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 2),
    );
  }

  // --- Construcción de Mapa Real OpenStreetMap ---
  Widget _buildOpenStreetMap(List<ReportEntity> reports, List<MunicipalCrewEntity> crews, MunicipalCrewEntity? initialCrew) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCrew == null
            ? const LatLng(_cityCenterLat, _cityCenterLng)
            : LatLng(initialCrew.latitude, initialCrew.longitude),
        initialZoom: initialCrew == null ? 14.2 : 15.5,
        minZoom: 3.0,
        maxZoom: 19.0,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        onTap: (_, __) {
          if (_selectedReportId != null || _selectedCrewId != null) {
            setState(() {
              _selectedReportId = null;
              _selectedCrewId = null;
            });
          }
        },
      ),
      children: [
        // 1. Teselas OpenStreetMap 100% libres
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ecoroute',
          maxZoom: 19,
        ),

        // 2. Capa de Cuadrillas Municipales y Reportes
        MarkerLayer(
          markers: [
            // Marcadores de Cuadrillas
            for (final crew in crews)
              _buildCrewMarker(crew),

            // Marcadores de Incidencias Ciudadanas
            for (final report in reports)
              _buildReportMarker(report),
          ],
        ),
      ],
    );
  }

  // Marcador interactivo de Cuadrilla Municipal
  Marker _buildCrewMarker(MunicipalCrewEntity crew) {
    final isSelected = _selectedCrewId == crew.id;

    return Marker(
      point: LatLng(crew.latitude, crew.longitude),
      width: isSelected ? 96 : 84,
      height: isSelected ? 76 : 66,
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedCrewId = crew.id;
            _selectedReportId = null;
          });
          _recenterMap(crew.latitude, crew.longitude);
        },
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A5835),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  crew.vehicleCode,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF047857),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Marcador interactivo de Reporte Ciudadano
  Marker _buildReportMarker(ReportEntity report) {
    final isSelected = _selectedReportId == report.id;
    final pinColor = _getReportPinColor(report);

    return Marker(
      point: LatLng(report.latitude, report.longitude),
      width: isSelected ? 86 : 74,
      height: isSelected ? 72 : 62,
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedReportId = report.id;
            _selectedCrewId = null;
          });
          _recenterMap(report.latitude, report.longitude);
        },
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F172A) : pinColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  report.reportNumber,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: pinColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 2)),
                  ],
                ),
                child: Icon(
                  report.priority == ReportPriority.high
                      ? Icons.warning_rounded
                      : Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getReportPinColor(ReportEntity report) {
    if (report.status == ReportStatus.resolved) return const Color(0xFF0284C7);
    switch (report.priority) {
      case ReportPriority.high:
        return const Color(0xFFDC2626);
      case ReportPriority.medium:
        return const Color(0xFFD97706);
      case ReportPriority.low:
        return const Color(0xFF059669);
    }
  }

  // --- Fallback Vectorial para Entornos de Pruebas ---
  Widget _buildTestVectorMap(List<ReportEntity> reports, List<MunicipalCrewEntity> crews) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_rounded, size: 48, color: Color(0xFF0A5835)),
              const SizedBox(height: 8),
              const Text(
                'Simulación de Mapa Macro Urbano (Test)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text('${reports.length} reportes geolocalizados'),
              Text('${crews.length} cuadrillas activas'),
              const SizedBox(height: 12),
              // Botón rápido para simular clic en reporte en tests
              if (reports.isNotEmpty)
                ElevatedButton(
                  onPressed: () => setState(() {
                    _selectedReportId = reports.first.id;
                    _selectedCrewId = null;
                  }),
                  child: const Text('Simular Selección de Reporte'),
                ),
              if (crews.isNotEmpty)
                ElevatedButton(
                  onPressed: () => setState(() {
                    _selectedCrewId = crews.first.id;
                    _selectedReportId = null;
                  }),
                  child: const Text('Simular Selección de Cuadrilla'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAssignModal({
    required ReportEntity report,
    required String adminId,
    required String adminName,
  }) {
    AdminAssignCrewModal.show(
      context: context,
      report: report,
      adminId: adminId,
      adminName: adminName,
    ).then((success) {
      if (success != true || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${report.reportNumber} asignado correctamente.')),
      );
    });
  }
}

class _MapFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final IconData? icon;
  final VoidCallback onTap;

  const _MapFilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? const Color(0xFF0A5835)) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (color ?? const Color(0xFF0A5835)) : const Color(0xFFCBD5E1),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x10000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : (color ?? const Color(0xFF475569))),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}
