import 'package:flutter/material.dart';

/// Tarjeta de perfil y estado de turno para el Personal de Limpieza.
/// Capa: Presentation (Widgets Staff)
class StaffShiftStatusCard extends StatelessWidget {
  final String staffName;
  final String squadName;
  final String shiftStatus;
  final Color statusColor;
  final VoidCallback onTapChangeStatus;

  const StaffShiftStatusCard({
    super.key,
    required this.staffName,
    this.squadName = 'Cuadrilla Zona Norte',
    required this.shiftStatus,
    required this.statusColor,
    required this.onTapChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
      ),
      child: Row(
        children: [
          // Avatar con ícono
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: Color(0xFF047857),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Datos del personal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staffName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  squadName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      shiftStatus,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botón para cambiar estado
          InkWell(
            onTap: onTapChangeStatus,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Cambiar estado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF047857),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF047857),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
