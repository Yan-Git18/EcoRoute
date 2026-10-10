import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../citizen/domain/entities/report_entity.dart';

/// Tarjeta flotante emergente para inspección y despacho de un reporte seleccionado en el mapa.
///
/// Ubicación: `lib/features/admin/presentation/widgets/admin_map_report_preview_card.dart`
/// Capa: Presentation (Widgets Admin)
class AdminMapReportPreviewCard extends StatelessWidget {
  final ReportEntity report;
  final VoidCallback onClose;
  final VoidCallback onAssignCrew;

  const AdminMapReportPreviewCard({
    super.key,
    required this.report,
    required this.onClose,
    required this.onAssignCrew,
  });

  Color _getPriorityColor(ReportPriority priority) {
    switch (priority) {
      case ReportPriority.high:
        return const Color(0xFFDC2626);
      case ReportPriority.medium:
        return const Color(0xFFD97706);
      case ReportPriority.low:
        return const Color(0xFF059669);
    }
  }

  String _getPriorityLabel(ReportPriority priority) {
    switch (priority) {
      case ReportPriority.high:
        return 'Alta Prioridad';
      case ReportPriority.medium:
        return 'Prioridad Media';
      case ReportPriority.low:
        return 'Prioridad Baja';
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(report.priority);
    final isPending = report.status == ReportStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: report.priority == ReportPriority.high
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Fila de Encabezado: Folio, Prioridad y Botón de Cierre
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: priorityColor.withAlpha(70)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_rounded, size: 12, color: priorityColor),
                        const SizedBox(width: 4),
                        Text(
                          _getPriorityLabel(report.priority),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Título de categoría y dirección
              Text(
                report.categoryName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.address,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Reportado por: ${report.citizenName}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // 3. Estado de Asignación si ya tiene cuadrilla
              if (report.assignedToTeamName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_rounded, size: 14, color: Color(0xFF059669)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Asignado a: ${report.assignedToTeamName} (${report.assignedVehicle ?? ""})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF065F46),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // 4. Botones de Acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.push(
                          RouteNames.citizenReportDetail.replaceFirst(':id', report.id),
                          extra: report,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Ver Detalle',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: onAssignCrew,
                      icon: Icon(
                        isPending ? Icons.send_rounded : Icons.swap_horiz_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      label: Text(
                        isPending ? 'Despachar' : 'Reasignar',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A5835),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
