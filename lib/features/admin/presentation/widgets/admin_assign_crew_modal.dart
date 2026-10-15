import 'package:flutter/material.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/municipal_crew_entity.dart';

/// Modal interactivo para la asignación de cuadrillas y vehículos a una incidencia.
///
/// Ubicación: `lib/features/admin/presentation/widgets/admin_assign_crew_modal.dart`
/// Capa: Presentation (Widgets Admin)
class AdminAssignCrewModal extends StatefulWidget {
  final ReportEntity report;
  final List<MunicipalCrewEntity> crews;
  final Future<bool> Function({
    required MunicipalCrewEntity crew,
    required ReportPriority priority,
    String? instructions,
  }) onConfirm;

  const AdminAssignCrewModal({
    super.key,
    required this.report,
    required this.crews,
    required this.onConfirm,
  });

  static Future<bool?> show({
    required BuildContext context,
    required ReportEntity report,
    required List<MunicipalCrewEntity> crews,
    required Future<bool> Function({
      required MunicipalCrewEntity crew,
      required ReportPriority priority,
      String? instructions,
    }) onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AdminAssignCrewModal(
          report: report,
          crews: crews,
          onConfirm: onConfirm,
        ),
      ),
    );
  }

  @override
  State<AdminAssignCrewModal> createState() => _AdminAssignCrewModalState();
}

class _AdminAssignCrewModalState extends State<AdminAssignCrewModal> {
  late MunicipalCrewEntity _selectedCrew;
  late ReportPriority _priority;
  final TextEditingController _instructionsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCrew = widget.crews.isNotEmpty
        ? widget.crews.first
        : const MunicipalCrewEntity(
            id: 'crew-default',
            name: 'Personal General',
            zone: 'Sector Central',
            leadStaffName: 'Mario Limpieza',
            vehicleCode: 'Camión #04',
            vehiclePlate: 'ECR-882',
          );
    _priority = widget.report.priority;
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final success = await widget.onConfirm(
      crew: _selectedCrew,
      priority: _priority,
      instructions: _instructionsController.text.trim(),
    );
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asa superior
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
            const SizedBox(height: 16),

            // Cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Despacho de Personal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Asignar atención para ${widget.report.reportNumber}',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tarjeta resumen del reporte
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A5835).withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Color(0xFF0A5835), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.report.categoryName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        Text(
                          widget.report.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. Selector de Personal Municipal
            const Text(
              'Seleccionar Personal de Campo:',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: widget.crews.map((crew) {
                final isSelected = _selectedCrew.id == crew.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCrew = crew),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF047857) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? const Color(0xFF047857) : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    crew.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: isSelected ? const Color(0xFF065F46) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      crew.vehicleCode,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${crew.leadStaffName} • ${crew.zone}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${crew.activeTasksCount} activas',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // 2. Nivel de Prioridad
            const Text(
              'Nivel de Urgencia / Prioridad:',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _PriorityOptionChip(
                  label: 'Baja',
                  color: const Color(0xFF10B981),
                  isSelected: _priority == ReportPriority.low,
                  onTap: () => setState(() => _priority = ReportPriority.low),
                ),
                const SizedBox(width: 10),
                _PriorityOptionChip(
                  label: 'Media',
                  color: const Color(0xFFF59E0B),
                  isSelected: _priority == ReportPriority.medium,
                  onTap: () => setState(() => _priority = ReportPriority.medium),
                ),
                const SizedBox(width: 10),
                _PriorityOptionChip(
                  label: 'Alta',
                  color: const Color(0xFFEF4444),
                  isSelected: _priority == ReportPriority.high,
                  onTap: () => setState(() => _priority = ReportPriority.high),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Instrucciones operativas
            const Text(
              'Instrucciones u observaciones (opcional):',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _instructionsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ej. Contenedor saturado, llevar pala y equipo de sanitización...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            // Botón de acción
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isSubmitting ? 'Despachando...' : 'Confirmar Despacho a Personal',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A5835),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityOptionChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityOptionChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(25) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFCBD5E1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
