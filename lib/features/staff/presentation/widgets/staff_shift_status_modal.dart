import 'package:flutter/material.dart';

/// Modal para seleccionar y cambiar el estado de turno del Personal de Limpieza.
/// Capa: Presentation (Widgets Staff)
class StaffShiftStatusModal {
  StaffShiftStatusModal._();

  static void show({
    required BuildContext context,
    required String currentStatus,
    required ValueChanged<String> onStatusSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Estado de turno operativo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                _ShiftOption(
                  title: 'En turno',
                  subtitle: 'Disponible y activo para atención de rutas',
                  color: const Color(0xFF10B981),
                  isSelected: currentStatus == 'En turno',
                  onTap: () {
                    onStatusSelected('En turno');
                    Navigator.pop(ctx);
                  },
                ),
                _ShiftOption(
                  title: 'En descanso',
                  subtitle: 'Pausa para refrigerio o mantenimiento',
                  color: const Color(0xFFF59E0B),
                  isSelected: currentStatus == 'En descanso',
                  onTap: () {
                    onStatusSelected('En descanso');
                    Navigator.pop(ctx);
                  },
                ),
                _ShiftOption(
                  title: 'Fin de turno',
                  subtitle: 'Jornada completada para el día',
                  color: const Color(0xFF94A3B8),
                  isSelected: currentStatus == 'Fin de turno',
                  onTap: () {
                    onStatusSelected('Fin de turno');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShiftOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShiftOption({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
