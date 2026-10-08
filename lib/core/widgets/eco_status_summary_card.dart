import 'package:flutter/material.dart';

/// Elemento de métrica individual para [EcoStatusSummaryCard].
class EcoStatusItem {
  final String count;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const EcoStatusItem({
    required this.count,
    required this.label,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });
}

/// Tarjeta métrica de resumen de estados de reporte y tareas.
/// Capa: Core (Widgets)
class EcoStatusSummaryCard extends StatelessWidget {
  final List<EcoStatusItem> items;
  final EdgeInsetsGeometry padding;

  const EcoStatusSummaryCard({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
  });

  @override
  Widget build(BuildContext context) {
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
      padding: padding,
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFF1F5F9),
              ),
            Expanded(
              child: _MetricColumn(item: items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final EcoStatusItem item;

  const _MetricColumn({required this.item});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: item.isSelected ? item.color.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.count,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: item.color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: item.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: item.isSelected ? item.color : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );

    if (item.onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.onTap,
        child: content,
      );
    }

    return content;
  }
}
