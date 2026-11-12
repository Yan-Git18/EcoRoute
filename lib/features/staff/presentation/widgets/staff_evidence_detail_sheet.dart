import 'package:flutter/material.dart';
import '../../../../core/widgets/eco_priority_indicator.dart';
import '../../../../core/widgets/evidence_image_card.dart';
import '../../domain/entities/staff_task_entity.dart';

/// Modal bottom sheet para que el Personal de Limpieza consulte la evidencia registrada de una tarea resuelta.
///
/// Principio SRP: Responsabilidad única de presentar la evidencia fotográfica, observaciones y metadatos de resolución.
/// Ubicación: `lib/features/staff/presentation/widgets/staff_evidence_detail_sheet.dart`
/// Capa: Presentation (Widgets Staff)
class StaffEvidenceDetailSheet extends StatelessWidget {
  final StaffTaskEntity task;

  const StaffEvidenceDetailSheet({super.key, required this.task});

  static void show(BuildContext context, StaffTaskEntity task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StaffEvidenceDetailSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = task.evidenceImageUrl != null && task.evidenceImageUrl!.trim().isNotEmpty;
    final notes = task.resolutionNotes?.trim();

    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manija superior
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Encabezado
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.task_alt_rounded,
                      color: Color(0xFF047857),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.categoryName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Incidencia ${task.reportNumber}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Resuelta ✓',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dirección y prioridad
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    task.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                EcoPriorityIndicator(priority: task.priority),
              ],
            ),
            const SizedBox(height: 18),

            // Título de la sección de evidencia
            const Text(
              'Evidencia fotográfica de limpieza',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            if (hasPhoto)
              EvidenceImageCard(
                imageUrl: task.evidenceImageUrl!,
                reportTitle: 'Evidencia ${task.reportNumber}',
                badgeLabel: 'Evidencia registrada',
                height: 220,
                borderRadius: BorderRadius.circular(18),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tarea finalizada sin fotografía adjunta.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),

            // Notas de resolución
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Notas del personal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  notes,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Botón de cerrar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
