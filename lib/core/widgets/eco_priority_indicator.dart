import 'package:flutter/material.dart';
import '../../features/citizen/domain/entities/report_entity.dart';

/// Indicador visual de nivel de prioridad mediante barras de señalización.
/// Capa: Core (Widgets)
class EcoPriorityIndicator extends StatelessWidget {
  final ReportPriority priority;

  const EcoPriorityIndicator({
    super.key,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (priority) {
      case ReportPriority.high:
        color = const Color(0xFFEF4444);
        label = 'Alta prioridad';
        break;
      case ReportPriority.medium:
        color = const Color(0xFFF59E0B);
        label = 'Media prioridad';
        break;
      case ReportPriority.low:
        color = const Color(0xFF10B981);
        label = 'Baja prioridad';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.signal_cellular_alt_rounded, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
