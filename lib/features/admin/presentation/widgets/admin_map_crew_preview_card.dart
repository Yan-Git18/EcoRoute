import 'package:flutter/material.dart';
import '../../domain/entities/municipal_crew_entity.dart';

/// Tarjeta flotante emergente para inspección de una cuadrilla seleccionada en el mapa macro.
///
/// Ubicación: `lib/features/admin/presentation/widgets/admin_map_crew_preview_card.dart`
/// Capa: Presentation (Widgets Admin)
class AdminMapCrewPreviewCard extends StatelessWidget {
  final MunicipalCrewEntity crew;
  final VoidCallback onClose;
  final VoidCallback onViewTasks;

  const AdminMapCrewPreviewCard({
    super.key,
    required this.crew,
    required this.onClose,
    required this.onViewTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
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
              // Encabezado con estado de disponibilidad y botón de cierre
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A5835).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF0A5835), size: 20),
                  ),
                  const SizedBox(width: 10),
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
                        Text(
                          '${crew.vehicleCode} • Placa ${crew.vehiclePlate}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
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
              const SizedBox(height: 12),

              // Detalles de Zona, Responsable y Carga
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Zona: ${crew.zone}',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_pin_circle_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Responsable: ${crew.leadStaffName}',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Badge de carga de trabajo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: crew.activeTasksCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      crew.activeTasksCount > 0 ? Icons.pending_actions_rounded : Icons.check_circle_outline_rounded,
                      size: 14,
                      color: crew.activeTasksCount > 0 ? const Color(0xFFD97706) : const Color(0xFF047857),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      crew.activeTasksCount > 0
                          ? '${crew.activeTasksCount} incidencias activas en ruta'
                          : 'Disponible sin carga asignada',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: crew.activeTasksCount > 0 ? const Color(0xFFB45309) : const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Botón de acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onViewTasks,
                  icon: const Icon(Icons.filter_list_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Ver Reportes Asignados',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
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
        ),
      ),
    );
  }
}
