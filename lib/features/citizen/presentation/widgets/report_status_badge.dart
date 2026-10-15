import 'package:flutter/material.dart';
import '../../domain/entities/report_entity.dart';

/// Badge visual estilizado para el estado del reporte.
///
/// Principio OCP: Obtiene los atributos visuales (colores, íconos y texto) a través de la extensión [ReportStatusX].
/// No requiere modificación cuando se incorporan nuevos estados al ciclo de vida.
///
/// Ubicación: `lib/features/citizen/presentation/widgets/report_status_badge.dart`
/// Capa: Presentation (Widgets)
class ReportStatusBadge extends StatelessWidget {
  final ReportStatus status;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const ReportStatusBadge({
    super.key,
    required this.status,
    this.showIcon = false,
    this.padding,
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.icon, size: 14, color: status.color),
            const SizedBox(width: 5),
          ],
          Text(
            status.displayLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
