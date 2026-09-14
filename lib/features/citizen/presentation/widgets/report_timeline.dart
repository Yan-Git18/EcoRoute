import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_entity.dart';

/// Ítem para la línea de tiempo de auditoría de un reporte.
class TimelineEvent {
  final String title;
  final String subtitle;
  final String time;
  final bool isCompleted;
  final bool isCurrent;

  const TimelineEvent({
    required this.title,
    required this.subtitle,
    required this.time,
    this.isCompleted = true,
    this.isCurrent = false,
  });
}

/// Componente visual de línea de tiempo para la trazabilidad del ciclo de vida del reporte.
///
/// Ubicación: `lib/features/citizen/presentation/widgets/report_timeline.dart`
/// Capa: Presentation (Widgets)
class ReportTimeline extends StatelessWidget {
  final ReportEntity report;

  const ReportTimeline({
    super.key,
    required this.report,
  });

  String _formatDateTime(DateTime date) {
    const months = [
      'sep.', 'oct.', 'nov.', 'dic.', 'ene.', 'feb.',
      'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.'
    ];
    final monthName = months[(date.month + 3) % 12];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'p. m.' : 'a. m.';
    return '${date.day} $monthName ${date.year} - $hour:$minute $period';
  }

  List<TimelineEvent> _buildEvents() {
    final events = <TimelineEvent>[];

    // Evento 1: Creación
    events.add(
      TimelineEvent(
        title: 'Reporte creado',
        subtitle: 'por ti',
        time: _formatDateTime(report.createdAt),
        isCompleted: true,
        isCurrent: report.status == ReportStatus.pending,
      ),
    );

    // Evento 2: En revisión / Asignación municipal
    final hasPassedPending = report.status == ReportStatus.assigned ||
        report.status == ReportStatus.inProgress ||
        report.status == ReportStatus.resolved;

    events.add(
      TimelineEvent(
        title: 'En revisión',
        subtitle: 'por la municipalidad',
        time: _formatDateTime(report.createdAt.add(const Duration(minutes: 45))),
        isCompleted: hasPassedPending,
        isCurrent: report.status == ReportStatus.assigned,
      ),
    );

    // Evento 3: En atención / Cuadrilla en camino
    final isInProgressOrResolved = report.status == ReportStatus.inProgress ||
        report.status == ReportStatus.resolved;

    events.add(
      TimelineEvent(
        title: 'En proceso',
        subtitle: 'cuadrilla de limpieza asignada',
        time: _formatDateTime(report.createdAt.add(const Duration(hours: 2))),
        isCompleted: isInProgressOrResolved,
        isCurrent: report.status == ReportStatus.inProgress,
      ),
    );

    // Evento 4: Resuelto
    if (report.status == ReportStatus.resolved) {
      events.add(
        TimelineEvent(
          title: 'Resuelto',
          subtitle: 'limpieza completada con evidencia',
          time: _formatDateTime(report.updatedAt ?? report.createdAt.add(const Duration(hours: 4))),
          isCompleted: true,
          isCurrent: true,
        ),
      );
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final events = _buildEvents();

    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isLast = index == events.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna del nodo y conector
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: event.isCompleted
                            ? AppColors.primary
                            : const Color(0xFFCBD5E1),
                        border: Border.all(
                          color: event.isCurrent ? AppColors.primary : Colors.white,
                          width: event.isCurrent ? 3 : 2,
                        ),
                        boxShadow: event.isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(80),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: event.isCompleted
                              ? AppColors.primary.withAlpha(150)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Contenido del evento
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.time,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                text: '${event.title} ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: event.isCompleted
                                      ? (event.title == 'En proceso'
                                          ? const Color(0xFF1D4ED8)
                                          : AppColors.forest)
                                      : const Color(0xFF94A3B8),
                                ),
                                children: [
                                  TextSpan(
                                    text: event.subtitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
