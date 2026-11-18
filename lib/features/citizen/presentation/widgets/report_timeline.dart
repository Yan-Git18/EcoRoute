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
      '',
      'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
      'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'
    ];
    final monthName = months[date.month];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'p. m.' : 'a. m.';
    return '${date.day} $monthName ${date.year} - $hour:$minute $period';
  }

  String _statusTitle(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Reporte creado';
      case ReportStatus.assigned:
        return 'En revisión';
      case ReportStatus.inProgress:
        return 'En proceso';
      case ReportStatus.resolved:
        return 'Resuelto';
      case ReportStatus.cancelled:
        return 'Cancelado';
    }
  }

  String _statusSubtitle(ReportHistoryItem item, ReportStatus status) {
    final comment = item.comment?.trim();
    if (comment != null && comment.isNotEmpty) {
      return '• $comment';
    }
    switch (status) {
      case ReportStatus.pending:
        return 'por ti';
      case ReportStatus.assigned:
        return item.changedByUserName != null && item.changedByUserName!.isNotEmpty
            ? 'por ${item.changedByUserName}'
            : 'por la municipalidad';
      case ReportStatus.inProgress:
        return item.changedByUserName != null && item.changedByUserName!.isNotEmpty
            ? 'atendido por ${item.changedByUserName}'
            : 'personal de limpieza asignado';
      case ReportStatus.resolved:
        return 'limpieza completada con evidencia';
      case ReportStatus.cancelled:
        return 'reporte cancelado por el ciudadano';
    }
  }

  List<TimelineEvent> _buildEvents() {
    if (report.history.isNotEmpty) {
      final sortedHistory = List<ReportHistoryItem>.from(report.history)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return List.generate(sortedHistory.length, (index) {
        final item = sortedHistory[index];
        final itemStatus = ReportStatus.fromString(item.newStatus);
        final isLast = index == sortedHistory.length - 1;

        return TimelineEvent(
          title: _statusTitle(itemStatus),
          subtitle: _statusSubtitle(item, itemStatus),
          time: _formatDateTime(item.timestamp),
          isCompleted: true,
          isCurrent: isLast,
        );
      });
    }

    final events = <TimelineEvent>[];

    // Evento 1: Creación (fecha real de creación)
    events.add(
      TimelineEvent(
        title: 'Reporte creado',
        subtitle: 'por ti',
        time: _formatDateTime(report.createdAt),
        isCompleted: true,
        isCurrent: report.status == ReportStatus.pending,
      ),
    );

    if (report.status == ReportStatus.cancelled) {
      events.add(
        TimelineEvent(
          title: 'Cancelado',
          subtitle: 'reporte cancelado por el ciudadano',
          time: report.updatedAt != null
              ? _formatDateTime(report.updatedAt!)
              : _formatDateTime(report.createdAt),
          isCompleted: true,
          isCurrent: true,
        ),
      );
      return events;
    }

    // Evento 2: En revisión / Asignación municipal
    final hasPassedPending = report.status == ReportStatus.assigned ||
        report.status == ReportStatus.inProgress ||
        report.status == ReportStatus.resolved;

    events.add(
      TimelineEvent(
        title: 'En revisión',
        subtitle: report.assignedToTeamName != null && report.assignedToTeamName!.isNotEmpty
            ? 'asignado a ${report.assignedToTeamName}'
            : 'por la municipalidad',
        time: hasPassedPending
            ? (report.status == ReportStatus.assigned && report.updatedAt != null
                ? _formatDateTime(report.updatedAt!)
                : 'Completado')
            : 'Pendiente de revisión',
        isCompleted: hasPassedPending,
        isCurrent: report.status == ReportStatus.assigned,
      ),
    );

    // Evento 3: En atención / Personal en camino
    final isInProgressOrResolved = report.status == ReportStatus.inProgress ||
        report.status == ReportStatus.resolved;

    events.add(
      TimelineEvent(
        title: 'En proceso',
        subtitle: report.assignedStaffName != null && report.assignedStaffName!.isNotEmpty
            ? 'atendido por ${report.assignedStaffName}'
            : 'personal de limpieza asignado',
        time: isInProgressOrResolved
            ? (report.status == ReportStatus.inProgress && report.updatedAt != null
                ? _formatDateTime(report.updatedAt!)
                : 'Completado')
            : 'Pendiente de atención',
        isCompleted: isInProgressOrResolved,
        isCurrent: report.status == ReportStatus.inProgress,
      ),
    );

    // Evento 4: Resuelto
    events.add(
      TimelineEvent(
        title: 'Resuelto',
        subtitle: 'limpieza completada con evidencia',
        time: report.status == ReportStatus.resolved
            ? (report.updatedAt != null
                ? _formatDateTime(report.updatedAt!)
                : _formatDateTime(report.createdAt))
            : 'Pendiente de resolución',
        isCompleted: report.status == ReportStatus.resolved,
        isCurrent: report.status == ReportStatus.resolved,
      ),
    );

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
              // Columna del nodo y conector vertical
              SizedBox(
                width: 18,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: event.isCompleted
                              ? AppColors.primary
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: event.isCompleted
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Contenido textual del evento
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 26.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.time,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          text: event.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: event.isCompleted ? FontWeight.w700 : FontWeight.w500,
                            color: event.isCompleted
                                ? AppColors.primary
                                : const Color(0xFF64748B),
                          ),
                          children: [
                            if (event.subtitle.isNotEmpty)
                              TextSpan(
                                text: ' ${event.subtitle}',
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
              ),
            ],
          ),
        );
      }),
    );
  }
}
