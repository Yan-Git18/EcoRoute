import 'package:flutter/material.dart';

import '../../../citizen/domain/entities/report_entity.dart';
import '../../../citizen/presentation/widgets/report_status_badge.dart';
import '../models/admin_map_report_status.dart';

class AdminMapReportGroupSheet extends StatelessWidget {
  const AdminMapReportGroupSheet({
    super.key,
    required this.reports,
    this.onZoom,
  });

  final List<ReportEntity> reports;
  final VoidCallback? onZoom;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView.builder(
          controller: controller,
          itemCount: reports.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Reportes cercanos', style: textTheme.titleLarge),
                        Text(
                          '${reports.length} reportes',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (onZoom != null)
                      TextButton.icon(
                        icon: const Icon(Icons.zoom_in_rounded),
                        label: const Text('Acercar'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onZoom!();
                        },
                      ),
                  ],
                ),
              );
            }

            final report = reports[index - 1];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 6,
              ),
              title: Text(report.reportNumber),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.categoryName),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (report.isReservedForRoute)
                        const Text('Asignado a una ruta')
                      else
                        ReportStatusBadge(status: report.status),
                      if (report.priority == ReportPriority.high)
                        Text(
                          report.priority.priorityFullLabel,
                          style: TextStyle(
                            color: report.priority.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              onTap: () => Navigator.of(context).pop(report),
            );
          },
        ),
      ),
    );
  }
}
