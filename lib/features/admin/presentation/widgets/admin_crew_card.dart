import 'package:flutter/material.dart';
import '../../domain/entities/municipal_crew_entity.dart';

/// Tarjeta administrativa para gestión de una cuadrilla municipal y su camión de recolección.
///
/// Ubicación: `lib/features/admin/presentation/widgets/admin_crew_card.dart`
/// Capa: Presentation (Widgets Admin)
class AdminCrewCard extends StatelessWidget {
  final MunicipalCrewEntity crew;
  final VoidCallback onEdit;
  final VoidCallback onViewOnMap;

  const AdminCrewCard({
    super.key,
    required this.crew,
    required this.onEdit,
    required this.onViewOnMap,
  });

  Color _getStatusColor(MunicipalCrewStatus status) {
    switch (status) {
      case MunicipalCrewStatus.available:
        return const Color(0xFF059669);
      case MunicipalCrewStatus.onRoute:
        return const Color(0xFF2563EB);
      case MunicipalCrewStatus.maintenance:
        return const Color(0xFFDC2626);
    }
  }

  Color _getStatusBg(MunicipalCrewStatus status) {
    switch (status) {
      case MunicipalCrewStatus.available:
        return const Color(0xFFECFDF5);
      case MunicipalCrewStatus.onRoute:
        return const Color(0xFFEFF6FF);
      case MunicipalCrewStatus.maintenance:
        return const Color(0xFFFEF2F2);
    }
  }

  IconData _getStatusIcon(MunicipalCrewStatus status) {
    switch (status) {
      case MunicipalCrewStatus.available:
        return Icons.check_circle_outline_rounded;
      case MunicipalCrewStatus.onRoute:
        return Icons.navigation_rounded;
      case MunicipalCrewStatus.maintenance:
        return Icons.build_circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(crew.status);
    final statusBg = _getStatusBg(crew.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: crew.status == MunicipalCrewStatus.maintenance
              ? const Color(0xFFFECACA)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera con Nombre de Cuadrilla, Placa y Badge de Estado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A5835).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Color(0xFF0A5835),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crew.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${crew.vehicleCode} • Placa ${crew.vehiclePlate}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(crew.status), size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        crew.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 2. Ficha de Operación: Tipo de vehículo, Dotación y Zona
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo de Unidad y Dotación
                Row(
                  children: [
                    Expanded(
                      child: _CrewDetailItem(
                        icon: Icons.directions_car_filled_outlined,
                        label: 'Tipo de Unidad',
                        value: crew.vehicleType,
                      ),
                    ),
                    Expanded(
                      child: _CrewDetailItem(
                        icon: Icons.people_outline_rounded,
                        label: 'Dotación',
                        value: '${crew.crewMembersCount} miembros',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Jefe de Cuadrilla y Zona
                Row(
                  children: [
                    Expanded(
                      child: _CrewDetailItem(
                        icon: Icons.person_pin_circle_outlined,
                        label: 'Líder Operario',
                        value: crew.leadStaffName,
                      ),
                    ),
                    Expanded(
                      child: _CrewDetailItem(
                        icon: Icons.map_outlined,
                        label: 'Carga Activa',
                        value: crew.activeTasksCount > 0
                            ? '${crew.activeTasksCount} incidencias'
                            : 'Sin carga',
                        valueColor: crew.activeTasksCount > 0
                            ? const Color(0xFFD97706)
                            : const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Zona asignada
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Sector: ${crew.zone}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Botones de Acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewOnMap,
                        icon: const Icon(Icons.map_rounded, size: 15),
                        label: const Text('Ver en Mapa', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.tune_rounded, size: 15, color: Colors.white),
                        label: const Text('Gestionar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A5835),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrewDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _CrewDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
