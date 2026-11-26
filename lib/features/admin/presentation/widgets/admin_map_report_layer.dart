import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../citizen/domain/entities/report_entity.dart';
import '../models/admin_map_report_groups.dart';
import '../models/admin_map_report_status.dart';

const adminMapAssignedColor = Color(0xFF1D4ED8);

class AdminMapReportLayer extends StatefulWidget {
  const AdminMapReportLayer({
    super.key,
    required this.reports,
    required this.selectedReportId,
    required this.onReportTap,
    required this.onGroupTap,
  });

  final List<ReportEntity> reports;
  final String? selectedReportId;
  final ValueChanged<ReportEntity> onReportTap;
  final ValueChanged<List<ReportEntity>> onGroupTap;

  @override
  State<AdminMapReportLayer> createState() => _AdminMapReportLayerState();
}

class _AdminMapReportLayerState extends State<AdminMapReportLayer> {
  static const _markerSize = 48.0;
  static const _spacing = 54.0;

  List<ReportEntity>? _groupedReports;
  double? _zoom;
  Crs? _crs;
  List<List<ReportEntity>> _groups = const [];

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    if (!identical(_groupedReports, widget.reports) ||
        _zoom != camera.zoom ||
        _crs != camera.crs) {
      _groupedReports = widget.reports;
      _zoom = camera.zoom;
      _crs = camera.crs;
      _groups = groupMapReports(
        widget.reports,
        spacing: _spacing,
        project: (report) => camera.project(_positionOf(report)),
      );
    }

    return MarkerLayer(
      markers: [
        for (final group in _groups)
          Marker(
            point: _positionOf(group.first),
            width: _markerSize,
            height: _markerSize,
            child: group.length == 1
                ? _singleMarker(group.single)
                : _groupMarker(group),
          ),
      ],
    );
  }

  LatLng _positionOf(ReportEntity report) =>
      LatLng(report.latitude, report.longitude);

  Widget _singleMarker(ReportEntity report) {
    final selected = report.id == widget.selectedReportId;
    return _ReportMapMarker(
      key: ValueKey('map-report-${report.id}'),
      label: 'Reporte ${report.reportNumber}, ${report.isReservedForRoute ? 'asignado a una ruta' : report.status.label}',
      color: report.isAssignedForOperations ? adminMapAssignedColor : report.priority.color,
      size: selected ? 40 : 32,
      onTap: () => widget.onReportTap(report),
      child: Icon(
        switch (report.status) {
          ReportStatus.inProgress => Icons.handyman_rounded,
          _ when report.isAssignedForOperations => Icons.assignment_ind_rounded,
          _ when report.priority == ReportPriority.high => Icons.warning_rounded,
          _ => Icons.delete_outline_rounded,
        },
        color: Colors.white,
        size: 17,
      ),
    );
  }

  Widget _groupMarker(List<ReportEntity> reports) {
    final assigned = reports.where((report) => report.isAssignedForOperations).length;
    final allAssigned = assigned == reports.length;
    final hasUrgent = reports.any((report) => report.priority == ReportPriority.high);
    return _ReportMapMarker(
      key: ValueKey('map-report-group-${reports.first.id}'),
      label: '${reports.length} reportes cercanos'
          '${assigned == 0 ? '' : ', $assigned asignados'}',
      color: allAssigned
          ? adminMapAssignedColor
          : assigned == 0 && hasUrgent ? ReportPriority.high.color : const Color(0xFF0F4C5C),
      size: 44,
      onTap: () => widget.onGroupTap(reports),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${reports.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportMapMarker extends StatelessWidget {
  const _ReportMapMarker({
    super.key,
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
    required this.child,
  });

  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ExcludeSemantics(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
