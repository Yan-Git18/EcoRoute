import 'package:flutter/material.dart';
import '../../domain/entities/report_entity.dart';

/// Badge visual estilizado para el estado del reporte.
///
/// Ubicación: `lib/features/citizen/presentation/widgets/report_status_badge.dart`
/// Capa: Presentation (Widgets)
class ReportStatusBadge extends StatelessWidget {
  final ReportStatus status;
  final bool showIcon;

  const ReportStatusBadge({
    super.key,
    required this.status,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final (label, bg, text, icon) = switch (status) {
      ReportStatus.pending => (
          'En revisión',
          const Color(0xFFE0F2FE),
          const Color(0xFF0369A1),
          Icons.schedule_rounded,
        ),
      ReportStatus.assigned => (
          'Asignado',
          const Color(0xFFEDE9FE),
          const Color(0xFF6D28D9),
          Icons.assignment_ind_rounded,
        ),
      ReportStatus.inProgress => (
          'En proceso',
          const Color(0xFFDBEAFE),
          const Color(0xFF1D4ED8),
          Icons.info_outline_rounded,
        ),
      ReportStatus.resolved => (
          'Resuelto',
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          Icons.check_circle_outline_rounded,
        ),
      ReportStatus.cancelled => (
          'Cancelado',
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C),
          Icons.cancel_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 14, color: text),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
