import 'package:flutter/material.dart';
import '../../../citizen/domain/entities/report_entity.dart';

/// Tarjeta de gestión administrativa de reporte.
///
/// Ubicación: `lib/features/admin/presentation/widgets/admin_report_card.dart`
/// Capa: Presentation (Widgets Admin)
class AdminReportCard extends StatelessWidget {
  final ReportEntity report;
  final VoidCallback onAssign;
  final VoidCallback onViewDetail;

  const AdminReportCard({
    super.key,
    required this.report,
    required this.onAssign,
    required this.onViewDetail,
  });

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes.clamp(1, 60)} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    } else {
      return 'Hace ${diff.inDays} d';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = report.status == ReportStatus.pending;
    final isResolved = report.status == ReportStatus.resolved;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending && report.priority == ReportPriority.high
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFE2E8F0),
          width: isPending && report.priority == ReportPriority.high ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera con Folio, Prioridad, Estado y Tiempo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.reportNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PriorityBadge(priority: report.priority),
                  ],
                ),
                Row(
                  children: [
                    _StatusBadge(status: report.status),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(report.createdAt),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 2. Información del residuo, dirección y ciudadano
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Reportado por: ${report.citizenName}${report.citizenPhone != null ? ' (${report.citizenPhone})' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),

                // Asignación de cuadrilla (si ya está asignada)
                if (report.assignedToTeamName != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_rounded, size: 16, color: Color(0xFF047857)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${report.assignedToTeamName} • ${report.assignedVehicle ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. Botones de acción administrativa
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: isPending
                      ? ElevatedButton.icon(
                          onPressed: onAssign,
                          icon: const Icon(Icons.assignment_ind_rounded, size: 17),
                          label: const Text('Despachar Personal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A5835),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: isResolved ? null : onAssign,
                          icon: const Icon(Icons.swap_horiz_rounded, size: 17),
                          label: Text(isResolved ? 'Incidencia Resuelta' : 'Reasignar Personal'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isResolved ? const Color(0xFF10B981) : const Color(0xFF0A5835),
                            side: BorderSide(
                              color: isResolved ? const Color(0xFF10B981) : const Color(0xFF0A5835),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Ver detalle completo',
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF64748B)),
                  onPressed: onViewDetail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final ReportPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (priority) {
      case ReportPriority.high:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'Alta';
        break;
      case ReportPriority.medium:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'Media';
        break;
      case ReportPriority.low:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        label = 'Baja';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ReportStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ReportStatus.pending:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'Pendiente';
        break;
      case ReportStatus.assigned:
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF6D28D9);
        label = 'Asignado';
        break;
      case ReportStatus.inProgress:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        label = 'En proceso';
        break;
      case ReportStatus.resolved:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF047857);
        label = 'Resuelto';
        break;
      case ReportStatus.cancelled:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
