import 'package:flutter/material.dart';
import '../../../../core/widgets/eco_action_pill.dart';
import '../../../../core/widgets/eco_priority_indicator.dart';
import '../../domain/entities/staff_task_entity.dart';

/// Tarjeta reutilizable de tarea operativa para el personal de limpieza.
/// Capa: Presentation (Widgets Staff)
class StaffTaskItemCard extends StatelessWidget {
  final StaffTaskEntity task;
  final bool isNextTask;
  final String? pendingActionLabel;
  final VoidCallback onStart;
  final VoidCallback onResolve;
  final VoidCallback? onViewEvidence;
  final VoidCallback? onViewDetail;

  const StaffTaskItemCard({
    super.key,
    required this.task,
    this.isNextTask = false,
    this.pendingActionLabel,
    required this.onStart,
    required this.onResolve,
    this.onViewEvidence,
    this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.reportNumber.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              task.reportNumber,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF047857),
              ),
            ),
          ),
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
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewDetail ?? (task.isResolved ? onViewEvidence : null),
          borderRadius: BorderRadius.circular(20),
          child: Container(
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
          ),
        ),
      );
    }

    return InkWell(
      onTap: onViewDetail ?? (task.isResolved ? onViewEvidence : null),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: rowContent,
      ),
    );
  }

  Widget _buildActionWidget() {
    if (task.isPending) {
      if (isNextTask) {
        return EcoActionPill(
          label: pendingActionLabel ?? 'Atender',
          textColor: const Color(0xFFB45309), // Ámbar oscuro
          backgroundColor: const Color(0xFFFEF3C7), // Ámbar suave
          icon: Icons.chevron_right_rounded,
          onTap: onStart,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        );
      }
      return EcoActionPill(
        label: pendingActionLabel ?? 'Iniciar',
        textColor: const Color(0xFFB45309), // Ámbar oscuro
        backgroundColor: const Color(0xFFFEF3C7), // Ámbar suave
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
      return EcoActionPill(
        label: 'Resuelta ✓',
        textColor: const Color(0xFF047857),
        backgroundColor: const Color(0xFFDCFCE7),
        icon: Icons.visibility_outlined,
        onTap: onViewEvidence,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      );
    }
  }
}
