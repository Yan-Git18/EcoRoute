import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Leyenda flotante para identificar el código de colores de los pines en el mapa interactivo.
///
/// Ubicación: `lib/features/citizen/presentation/widgets/citizen_map_legend.dart`
/// Capa: Presentation (Widgets)
class CitizenMapLegend extends StatefulWidget {
  const CitizenMapLegend({super.key});

  @override
  State<CitizenMapLegend> createState() => _CitizenMapLegendState();
}

class _CitizenMapLegendState extends State<CitizenMapLegend> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(245),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 16,
                  color: Color(0xFF475569),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Leyenda',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            _LegendItem(
              color: AppColors.statusPending,
              label: 'Pendiente',
            ),
            const SizedBox(height: 5),
            _LegendItem(
              color: AppColors.statusInProgress,
              label: 'En proceso',
            ),
            const SizedBox(height: 5),
            _LegendItem(
              color: AppColors.statusResolved,
              label: 'Resuelto',
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(90),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}
