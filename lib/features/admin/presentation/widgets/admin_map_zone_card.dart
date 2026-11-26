import 'package:flutter/material.dart';

import '../../../../core/geo/cajamarca_urban_zones.dart';
import 'admin_map_zone_layer.dart';

class AdminMapZoneCard extends StatelessWidget {
  const AdminMapZoneCard({
    super.key,
    required this.zone,
    required this.count,
    this.filteredCount,
    required this.isLoading,
    required this.hasError,
    required this.onClose,
    required this.onRetry,
    required this.onViewReports,
  });

  final CajamarcaZone zone;
  final int? count;
  final int? filteredCount;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onClose;
  final VoidCallback onRetry;
  final VoidCallback onViewReports;

  @override
  Widget build(BuildContext context) {
    final reportCount = count;
    final summary = switch (reportCount) {
      null when isLoading => 'Contando reportes…',
      null => 'Conteo no disponible',
      _ when filteredCount != null => '$filteredCount de $reportCount reportes con el filtro',
      1 => '1 reporte',
      _ => '$reportCount reportes',
    };
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, color: adminZoneColors[zone], size: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        zone.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar zona',
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: hasError && !isLoading
                            ? TextButton(
                                onPressed: onRetry,
                                child: Text('$summary · Reintentar'),
                              )
                            : Text(summary),
                      ),
                    ),
                    FilledButton(
                      onPressed: onViewReports,
                      child: const Text('Ver todos'),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
