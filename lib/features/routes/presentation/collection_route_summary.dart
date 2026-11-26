import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../domain/collection_route.dart';
import 'collection_route_map.dart';

String routeWindowLabel(BuildContext context, RouteWindow window) {
  final localizations = MaterialLocalizations.of(context);
  String time(DateTime date) => localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(date),
    alwaysUse24HourFormat: true,
  );
  final sameDay = DateUtils.isSameDay(window.start, window.end);
  final endDate = sameDay
      ? ''
      : '${DateFormatter.formatShortDate(window.end)} ';
  return '${DateFormatter.formatShortDate(window.start)} · ${time(window.start)} – $endDate${time(window.end)}';
}

String routeStopLabel(CollectionStop stop) => [
  stop.number,
  if (stop.category.isNotEmpty) stop.category,
  'Prioridad ${stop.priority.label.toLowerCase()}',
].join(' · ');

class CollectionRouteSummary extends StatelessWidget {
  const CollectionRouteSummary({
    super.key,
    required this.route,
    this.onStopTap,
  });

  final CollectionRoute route;
  final ValueChanged<CollectionStop>? onStopTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(route.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('${route.zone.name} · ${route.status.label}'),
        Text('${route.crewName} · ${route.vehicle}'),
        Text(routeWindowLabel(context, route.window)),
        const SizedBox(height: 16),
        CollectionRouteMap(
          key: ValueKey(route.id),
          stops: route.stops,
          geometry: route.geometry,
          onStopTap: onStopTap,
          completedStops: route.completedStops,
          skippedReportIds: route.skippedStops.keys.toSet(),
          nextStopIndex: route.status == CollectionRouteStatus.inProgress
              ? route.completedStops
              : null,
        ),
        const SizedBox(height: 8),
        RouteTravelEstimate(
          stopCount: route.stops.length,
          distanceMeters: route.distanceMeters,
          durationSeconds: route.durationSeconds,
        ),
        const SizedBox(height: 16),
        Text(
          '${route.completedStops - route.skippedStops.length} de ${route.stops.length} paradas atendidas'
          '${route.skippedStops.isEmpty ? '' : ' · ${route.skippedStops.length} sin atender'}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final (index, stop) in route.stops.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: index < route.completedStops
                  ? Icon(
                      route.skippedStops.containsKey(stop.reportId)
                          ? Icons.report_outlined
                          : Icons.check,
                    )
                  : Text('${index + 1}'),
            ),
            title: Text(
              stop.address.isEmpty ? 'Reporte ${stop.number}' : stop.address,
            ),
            subtitle: Text(
              route.skippedStops.containsKey(stop.reportId)
                  ? 'No atendida · ${route.skippedStops[stop.reportId]}'
                  : index == route.completedStops &&
                        route.status == CollectionRouteStatus.inProgress
                  ? 'Siguiente parada · ${routeStopLabel(stop)}'
                  : routeStopLabel(stop),
            ),
            trailing: onStopTap == null
                ? null
                : const Icon(Icons.chevron_right),
            onTap: onStopTap == null ? null : () => onStopTap!(stop),
          ),
      ],
    );
  }
}

class RouteTravelEstimate extends StatelessWidget {
  const RouteTravelEstimate({
    super.key,
    required this.stopCount,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final int stopCount;
  final double? distanceMeters;
  final int? durationSeconds;

  @override
  Widget build(BuildContext context) {
    final distance = distanceMeters;
    final duration = durationSeconds;
    if (stopCount < 2) {
      return const Text('Una parada, sin traslado entre paradas.');
    }
    if (distance == null || duration == null) {
      return const Text('Recorrido por calles no disponible.');
    }
    final distanceLabel = distance < 1000
        ? '${distance.round()} m'
        : '${(distance / 1000).toStringAsFixed(1)} km';
    final minutes = (duration / 60).ceil();
    return Text('$distanceLabel · $minutes min de traslado entre paradas');
  }
}
