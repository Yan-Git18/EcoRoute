import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/geo_constants.dart';
import '../../../../core/geo/cajamarca_urban_zones.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../models/admin_map_report_status.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_assign_crew_modal.dart';
import '../widgets/admin_back_button.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/admin_load_notice.dart';
import '../widgets/admin_map_crew_preview_card.dart';
import '../widgets/admin_map_report_group_sheet.dart';
import '../widgets/admin_map_report_layer.dart';
import '../widgets/admin_map_report_preview_card.dart';
import '../widgets/admin_map_zone_card.dart';
import '../widgets/admin_map_zone_layer.dart';

/// Filtros para la visualización de capas en el mapa macro urbano.
enum AdminMapFilter {
  all('Todas'),
  urgent('Urgentes'),
  pending('Pendientes'),
  assigned('Asignados'),
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
  CajamarcaZone? _selectedZone;
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
  static const double _maxZoom = 19;

  bool get _isFlutterTest {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  static final _urbanCameraFit = CameraFit.bounds(
    bounds: AppGeoConstants.cajamarcaBounds,
    padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
  );

  void _selectZone(CajamarcaZone? zone) {
    setState(() {
      _selectedZone = zone;
      if (zone != null && _activeFilter == AdminMapFilter.crews) {
        _activeFilter = AdminMapFilter.all;
      }
      _selectedReportId = null;
      _selectedCrewId = null;
    });
  }

  void _selectReport(ReportEntity report) {
    setState(() {
      _selectedReportId = report.id;
      _selectedCrewId = null;
    });
  }

  void _selectFilter(AdminMapFilter filter) {
    setState(() {
      _activeFilter = filter;
      if (filter == AdminMapFilter.crews) _selectedZone = null;
      _selectedReportId = null;
      _selectedCrewId = null;
    });
  }

  Future<void> _openReportGroup(List<ReportEntity> reports) async {
    final coordinates = {
      for (final report in reports) LatLng(report.latitude, report.longitude),
    };
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = math.min(currentZoom + 2, _maxZoom);
    final canZoom = coordinates.length > 1 && targetZoom > currentZoom;
    final selected = await showModalBottomSheet<ReportEntity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AdminMapReportGroupSheet(
        reports: reports,
        onZoom: canZoom
            ? () {
                _mapController.fitCamera(
                  CameraFit.coordinates(
                    coordinates: coordinates.toList(),
                    padding: const EdgeInsets.fromLTRB(32, 72, 32, 32),
                    maxZoom: targetZoom,
                  ),
                );
              }
            : null,
      ),
    );
    if (mounted && selected != null) _selectReport(selected);
  }

  List<ReportEntity> _getFilteredReports(List<ReportEntity> allReports) {
    switch (_activeFilter) {
      case AdminMapFilter.all:
        return allReports;
      case AdminMapFilter.urgent:
        return allReports.where((r) => r.priority == ReportPriority.high).toList();
      case AdminMapFilter.pending:
        return allReports.where((report) => !report.isAssignedForOperations).toList();
      case AdminMapFilter.assigned:
        return allReports.where((report) => report.isAssignedForOperations).toList();
      case AdminMapFilter.crews:
        return [];
    }
  }

  List<MunicipalCrewEntity> _getFilteredCrews(List<MunicipalCrewEntity> allCrews) {
    if (_activeFilter != AdminMapFilter.all && _activeFilter != AdminMapFilter.crews) {
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

    final urbanReports = ref.watch(urbanReportsProvider);
    final zones = urbanReports.value;
    final selectedZone = _selectedZone;
    final zonedReports = selectedZone == null
        ? [for (final group in zones?.values ?? const <List<ReportEntity>>[]) ...group]
        : zones?[selectedZone] ?? const <ReportEntity>[];
    final reports = zonedReports.where((report) => report.isOpenForOperations).toList();
    final crews = adminReportsState.teams;
    final hasReports = urbanReports.hasValue;
    final hasCrews = adminReportsState.hasLoadedCrews;
    final selectedReport = reports
        .where((report) => report.id == _selectedReportId)
        .firstOrNull;
    final selectedCrew = crews
        .where((crew) => crew.id == _selectedCrewId && crew.hasLocation)
        .firstOrNull;
    final initialCrew = crews
        .where((crew) => crew.id == widget.initialCrewId && crew.hasLocation)
        .firstOrNull;
    final visibleReports = _getFilteredReports(reports);
    final visibleCrews = _getFilteredCrews(crews);

    final urgentCount = reports.where((r) => r.priority == ReportPriority.high).length;
    final assignedCount = reports.where((report) => report.isAssignedForOperations).length;
    final pendingCount = reports.length - assignedCount;

    final totals = adminReportsState.totals;
    final municipalTotal = switch (_activeFilter) {
      AdminMapFilter.all when totals != null => totals.pending + totals.assigned + totals.inProgress,
      _ => null,
    };
    final mapCount = visibleReports.length;
    final subtitle = switch (_activeFilter) {
      AdminMapFilter.crews => '${visibleCrews.length} equipos en el mapa',
      _ when !hasReports => urbanReports.hasError ? 'Reportes no disponibles' : 'Cargando incidencias…',
      _ when selectedZone == null && municipalTotal != null && municipalTotal > mapCount =>
        '$mapCount de $municipalTotal en zona urbana',
      _ => '$mapCount incidencias abiertas en el mapa',
    };
    void refresh() {
      ref.invalidate(urbanReportsProvider);
      viewModel.refresh();
    }

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
              subtitle,
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
            onPressed: urbanReports.isLoading || adminReportsState.isLoading
                ? null
                : refresh,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          AdminLoadNotice(
            state: adminReportsState.copyWith(
              reportsLoadFailed: urbanReports.hasError,
              hasLoadedReports: hasReports,
              isLoading: urbanReports.isLoading || adminReportsState.isLoading,
            ),
            onRetry: refresh,
          ),
          if (widget.initialCrewId == null ||
              hasCrews ||
              !adminReportsState.isLoading)
            Expanded(
              child: Stack(
                children: [
                  // 1. Mapa base, sectores urbanos y marcadores operativos
                  Positioned.fill(
                    child: _buildOpenStreetMap(
                      visibleReports,
                      visibleCrews,
                      initialCrew,
                    ),
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
                            onTap: () => _selectFilter(AdminMapFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _MapFilterChip(
                            label: 'Pendientes (${hasReports ? pendingCount : '—'})',
                            isSelected: _activeFilter == AdminMapFilter.pending,
                            color: const Color(0xFFD97706),
                            icon: Icons.pending_actions_rounded,
                            onTap: () => _selectFilter(AdminMapFilter.pending),
                          ),
                          const SizedBox(width: 8),
                          _MapFilterChip(
                            label: 'Asignados (${hasReports ? assignedCount : '—'})',
                            isSelected: _activeFilter == AdminMapFilter.assigned,
                            color: adminMapAssignedColor,
                            icon: Icons.assignment_ind_rounded,
                            onTap: () => _selectFilter(AdminMapFilter.assigned),
                          ),
                          const SizedBox(width: 8),
                          _MapFilterChip(
                            label: 'Urgentes (${hasReports ? urgentCount : '—'})',
                            isSelected: _activeFilter == AdminMapFilter.urgent,
                            color: const Color(0xFFDC2626),
                            icon: Icons.priority_high_rounded,
                            onTap: () => _selectFilter(AdminMapFilter.urgent),
                          ),
                          const SizedBox(width: 8),
                          _MapFilterChip(
                            label: 'Personal (${hasCrews ? crews.length : '—'})',
                            isSelected: _activeFilter == AdminMapFilter.crews,
                            color: const Color(0xFF047857),
                            icon: Icons.local_shipping_rounded,
                            onTap: () => _selectFilter(AdminMapFilter.crews),
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
                        constraints: const BoxConstraints(
                          maxWidth: 280,
                          maxHeight: 320,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(245),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 3)),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Zonas urbanas',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                children: [
                                  for (final zone in CajamarcaZone.values)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                      ),
                                      onPressed: () {
                                        _showLegend = false;
                                        _selectZone(zone);
                                      },
                                      child: _LegendItem(
                                        color: adminZoneColors[zone]!,
                                        label: zone.name,
                                      ),
                                    ),
                                ],
                              ),
                              const Divider(),
                              const Text(
                                'Marcadores',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              const _LegendItem(
                                color: Color(0xFFDC2626),
                                label: 'Pendiente urgente',
                              ),
                              const _LegendItem(
                                color: Color(0xFFD97706),
                                label: 'Pendiente · Prioridad media',
                              ),
                              const _LegendItem(
                                color: Color(0xFF059669),
                                label: 'Pendiente · Prioridad baja',
                              ),
                              const _LegendItem(
                                color: adminMapAssignedColor,
                                label: 'Asignado o en atención',
                              ),
                              const _LegendItem(
                                color: Color(0xFF0A5835),
                                label: 'Personal Activo (Camión)',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 4. Botón flotante para recentrar mapa
                  Positioned(
                    bottom: selectedReport != null || selectedCrew != null
                        ? 260
                        : selectedZone != null
                        ? 128
                        : 20,
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'recenter_admin_map',
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0A5835),
                      elevation: 4,
                      tooltip: 'Ver toda el área urbana',
                      onPressed: () =>
                          _mapController.fitCamera(_urbanCameraFit),
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
                        onAssignCrew: selectedReport.isReservedForRoute ||
                                selectedReport.status == ReportStatus.inProgress
                            ? null
                            : () => _openAssignModal(
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
                  if (selectedZone != null && selectedReport == null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: AdminMapZoneCard(
                        zone: selectedZone,
                        count: hasReports ? reports.length : null,
                        filteredCount: _activeFilter == AdminMapFilter.all
                            ? null
                            : visibleReports.length,
                        isLoading: urbanReports.isLoading,
                        hasError: urbanReports.hasError,
                        onClose: () => _selectZone(null),
                        onRetry: () => ref.invalidate(urbanReportsProvider),
                        onViewReports: () => context.go(
                          RouteNames.adminReportsByZone(selectedZone.id, openOnly: true),
                        ),
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
        initialCameraFit: initialCrew == null ? _urbanCameraFit : null,
        minZoom: 3.0,
        maxZoom: _maxZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onTap: (_, point) => _selectZone(
          CajamarcaUrbanZones.zoneAt(point.latitude, point.longitude),
        ),
      ),
      children: [
        // 1. Teselas OpenStreetMap 100% libres
        if (!_isFlutterTest)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.ecoroute',
            maxZoom: 19,
          ),

        AdminMapZoneLayer(selectedZone: _selectedZone),

        MarkerLayer(
          markers: [for (final crew in crews) _buildCrewMarker(crew)],
        ),
        AdminMapReportLayer(
          reports: reports,
          selectedReportId: _selectedReportId,
          onReportTap: _selectReport,
          onGroupTap: _openReportGroup,
        ),
        SimpleAttributionWidget(
          alignment: Alignment.bottomLeft,
          source: const Text('OpenStreetMap'),
          onTap: () => launchUrl(
            Uri.https('www.openstreetmap.org', '/copyright'),
          ),
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
            _selectedZone = null;
          });
          _mapController.move(LatLng(crew.latitude, crew.longitude), 14.5);
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
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}
