import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/route_navigation_service.dart';
import '../domain/collection_route.dart';

class CollectionRouteMap extends StatelessWidget {
  const CollectionRouteMap({
    super.key,
    required this.stops,
    this.color = AppColors.primary,
    this.geometry = const [],
    this.onStopTap,
    this.selectedReports,
    this.completedStops = 0,
    this.skippedReportIds = const {},
    this.nextStopIndex,
    this.workerPosition,
    this.navigationLeg,
    this.height = 240,
    this.controller,
    this.focus,
  });

  final List<CollectionStop> stops;
  final Color color;
  final List<LatLng> geometry;
  final ValueChanged<CollectionStop>? onStopTap;

  final Set<String>? selectedReports;
  final int completedStops;
  final Set<String> skippedReportIds;
  final int? nextStopIndex;
  final LatLng? workerPosition;
  final RouteInfoResult? navigationLeg;
  final double? height;
  final MapController? controller;
  final LatLng? focus;

  static const _colors = [
    AppColors.primary,
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFB45309),
    Color(0xFFBE185D),
    Color(0xFF0E7490),
  ];

  static Color groupColor(int index) => _colors[index % _colors.length];

  @override
  Widget build(BuildContext context) {
    final bounds = <LatLng>{
      ...stops.map((stop) => stop.location),
      ...geometry,
    }.toList();
    if (bounds.isEmpty) return const SizedBox.shrink();

    final markers = [
      for (final (index, stop) in stops.indexed)
        if (index != nextStopIndex) _stopMarker(index, stop),
      if (nextStopIndex case final index? when index < stops.length)
        _stopMarker(index, stops[index]),
    ];

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: focus ?? bounds.first,
            initialZoom: focus == null ? 16 : 17,
            initialCameraFit: focus != null || bounds.length < 2
                ? null
                : CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(bounds),
                    padding: const EdgeInsets.all(32),
                    maxZoom: 17,
                  ),
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST'))
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ecoroute',
              ),
            if (geometry.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(points: geometry, strokeWidth: 4, color: color),
                ],
              ),
            if (navigationLeg case final leg? when leg.points.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: leg.points,
                    strokeWidth: 5,
                    color: const Color(0xFF1D4ED8),
                    pattern: leg.isApproximate
                        ? const StrokePattern.dotted()
                        : const StrokePattern.solid(),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (workerPosition case final position?)
                  Marker(
                    point: position,
                    width: 40,
                    height: 40,
                    child: const Tooltip(
                      message: 'Tu ubicación',
                      child: CircleAvatar(
                        backgroundColor: Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        child: Icon(Icons.local_shipping),
                      ),
                    ),
                  ),
                ...markers,
              ],
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: InkWell(
                  onTap: () => launchUrl(
                    Uri.https('www.openstreetmap.org', '/copyright'),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Text(
                      '© OpenStreetMap',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _stopMarker(int stopIndex, CollectionStop stop) => Marker(
    point: stop.location,
    width: 32,
    height: 32,
    child: Semantics(
      label:
          'Parada ${stopIndex + 1}, reporte ${stop.number}'
          '${stopIndex == nextStopIndex ? ', siguiente' : ''}'
          '${skippedReportIds.contains(stop.reportId)
              ? ', no atendida'
              : stopIndex < completedStops
              ? ', atendida'
              : ''}',
      button: onStopTap != null,
      child: GestureDetector(
        onTap: onStopTap == null ? null : () => onStopTap!(stop),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: stopIndex == nextStopIndex
                ? const Color(0xFF1D4ED8)
                : stopIndex < completedStops ||
                      selectedReports?.contains(stop.reportId) == false
                ? const Color(0xFF475569)
                : color,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: stopIndex < completedStops
                ? Icon(
                    skippedReportIds.contains(stop.reportId)
                        ? Icons.report_outlined
                        : Icons.check,
                    size: 18,
                    color: Colors.white,
                  )
                : Text(
                    '${stopIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}
