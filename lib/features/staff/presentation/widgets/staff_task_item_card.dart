import 'package:flutter/material.dart';
import '../../../../core/widgets/eco_action_pill.dart';
import '../../../../core/widgets/eco_priority_indicator.dart';
import '../../domain/entities/staff_task_entity.dart';

/// Tarjeta reutilizable de tarea operativa para el personal de limpieza.
/// Capa: Presentation (Widgets Staff)
class StaffTaskItemCard extends StatelessWidget {
  final StaffTaskEntity task;
  final bool isNextTask;
  final VoidCallback onStart;
  final VoidCallback onResolve;

  const StaffTaskItemCard({
    super.key,
    required this.task,
    this.isNextTask = false,
    required this.onStart,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.categoryName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 16,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                task.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        EcoPriorityIndicator(priority: task.priority),
      ],
    );

    final actionWidget = _buildActionWidget();

    final rowContent = Row(
      children: [
        Expanded(child: infoColumn),
        const SizedBox(width: 10),
        actionWidget,
      ],
    );

    if (isNextTask) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: rowContent,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: rowContent,
    );
  }

  Widget _buildActionWidget() {
    if (task.isPending) {
      if (isNextTask) {
        return EcoActionPill(
          label: 'Atender',
          textColor: const Color(0xFFDC2626),
          backgroundColor: const Color(0xFFFEE2E2),
          icon: Icons.chevron_right_rounded,
          onTap: onStart,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        );
      }
      return EcoActionPill(
        label: 'Iniciar',
        textColor: const Color(0xFF047857),
        backgroundColor: const Color(0xFFDCFCE7),
        icon: Icons.chevron_right_rounded,
        onTap: onStart,
      );
    } else if (task.isInProgress) {
      return EcoActionPill(
        label: 'Resolver',
        textColor: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFFDBEAFE),
        icon: Icons.chevron_right_rounded,
        onTap: onResolve,
        padding: isNextTask
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      );
    } else {
      return const EcoActionPill(
        label: 'Resuelta ✓',
        textColor: Color(0xFF047857),
        backgroundColor: Color(0xFFDCFCE7),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      );
    }
  }
}
