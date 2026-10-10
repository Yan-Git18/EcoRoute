import 'package:flutter/material.dart';
import '../../domain/entities/municipal_crew_entity.dart';

/// Modal bottom sheet para ajustar estado operativo y zona de una cuadrilla.
///
/// Ubicación: `lib/features/admin/presentation/widgets/admin_crew_edit_modal.dart`
/// Capa: Presentation (Widgets Admin)
class AdminCrewEditModal extends StatefulWidget {
  final MunicipalCrewEntity crew;
  final Future<void> Function({
    required MunicipalCrewStatus status,
    required String zone,
    required bool isAvailable,
  }) onConfirm;

  const AdminCrewEditModal({
    super.key,
    required this.crew,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required MunicipalCrewEntity crew,
    required Future<void> Function({
      required MunicipalCrewStatus status,
      required String zone,
      required bool isAvailable,
    }) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdminCrewEditModal(crew: crew, onConfirm: onConfirm),
    );
  }

  @override
  State<AdminCrewEditModal> createState() => _AdminCrewEditModalState();
}

class _AdminCrewEditModalState extends State<AdminCrewEditModal> {
  late MunicipalCrewStatus _selectedStatus;
  late TextEditingController _zoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.crew.status;
    _zoneController = TextEditingController(text: widget.crew.zone);
  }

  @override
  void dispose() {
    _zoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de arrastre
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A5835).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFF0A5835), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestionar ${widget.crew.name}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      '${widget.crew.vehicleCode} • Placa ${widget.crew.vehiclePlate}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // 1. Selector de Estado Operativo
          const Text('Estado Operativo de la Unidad', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final st in MunicipalCrewStatus.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedStatus = st),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedStatus == st ? const Color(0xFF0A5835) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedStatus == st ? const Color(0xFF0A5835) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              st == MunicipalCrewStatus.available
                                  ? Icons.check_circle_outline_rounded
                                  : st == MunicipalCrewStatus.onRoute
                                      ? Icons.navigation_rounded
                                      : Icons.build_circle_outlined,
                              size: 18,
                              color: _selectedStatus == st ? Colors.white : const Color(0xFF64748B),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              st.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _selectedStatus == st ? Colors.white : const Color(0xFF334155),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Campo de Zona / Sector
          const Text('Sector de Cobertura Asignado', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          TextField(
            controller: _zoneController,
            decoration: InputDecoration(
              hintText: 'Ej. Sector 1 (Centro)',
              prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF64748B), size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Botón Guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      setState(() => _isSaving = true);
                      await widget.onConfirm(
                        status: _selectedStatus,
                        zone: _zoneController.text.trim().isNotEmpty ? _zoneController.text.trim() : widget.crew.zone,
                        isAvailable: _selectedStatus != MunicipalCrewStatus.maintenance,
                      );
                      if (mounted) {
                        navigator.pop();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5835),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar Cambios de Unidad', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
