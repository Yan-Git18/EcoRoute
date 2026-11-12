import 'package:flutter/material.dart';
import '../../domain/entities/municipal_crew_entity.dart';

/// Modal bottom sheet para ajustar estado operativo, asignación y vehículo de una cuadrilla.
///
/// Ubicación: `lib/features/admin/presentation/widgets/admin_crew_edit_modal.dart`
/// Capa: Presentation (Widgets Admin)
class AdminCrewEditModal extends StatefulWidget {
  final MunicipalCrewEntity crew;
  final Future<void> Function({
    required MunicipalCrewStatus status,
    required String zone,
    required bool isAvailable,
    String? leadStaffName,
    String? vehicleCode,
    String? vehiclePlate,
  }) onConfirm;
  final Future<void> Function()? onDelete;

  const AdminCrewEditModal({
    super.key,
    required this.crew,
    required this.onConfirm,
    this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required MunicipalCrewEntity crew,
    required Future<void> Function({
      required MunicipalCrewStatus status,
      required String zone,
      required bool isAvailable,
      String? leadStaffName,
      String? vehicleCode,
      String? vehiclePlate,
    }) onConfirm,
    Future<void> Function()? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdminCrewEditModal(
        crew: crew,
        onConfirm: onConfirm,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<AdminCrewEditModal> createState() => _AdminCrewEditModalState();
}

class _AdminCrewEditModalState extends State<AdminCrewEditModal> {
  late MunicipalCrewStatus _selectedStatus;
  late TextEditingController _zoneController;
  late TextEditingController _leaderController;
  late TextEditingController _vehicleCodeController;
  late TextEditingController _vehiclePlateController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.crew.status;
    _zoneController = TextEditingController(text: widget.crew.zone);
    _leaderController = TextEditingController(text: widget.crew.leadStaffName);
    _vehicleCodeController = TextEditingController(text: widget.crew.vehicleCode);
    _vehiclePlateController = TextEditingController(text: widget.crew.vehiclePlate);
  }

  @override
  void dispose() {
    _zoneController.dispose();
    _leaderController.dispose();
    _vehicleCodeController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar baja de unidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('¿Está seguro de que desea eliminar la cuadrilla "${widget.crew.name}" del registro de Firestore?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onDelete != null) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      setState(() => _isSaving = true);
      await widget.onDelete!();
      if (mounted) {
        navigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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

            // 2. Sector de Cobertura
            const Text('Sector de Cobertura Asignado', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 8),
            TextField(
              controller: _zoneController,
              decoration: _inputDecoration('Ej. Sector 1 (Centro)', Icons.map_outlined),
            ),
            const SizedBox(height: 14),

            // 3. Responsable / Líder
            const Text('Líder o Responsable de Cuadrilla', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 8),
            TextField(
              controller: _leaderController,
              decoration: _inputDecoration('Ej. Mario Limpieza', Icons.person_outline_rounded),
            ),
            const SizedBox(height: 14),

            // 4. Código y Placa Vehicular
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Código Vehículo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _vehicleCodeController,
                        decoration: _inputDecoration('Ej. Camión #04', Icons.local_shipping_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Placa Vehicular', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _vehiclePlateController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _inputDecoration('Ej. ECR-882', Icons.pin_outlined),
                      ),
                    ],
                  ),
                ),
              ],
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
                          leadStaffName: _leaderController.text.trim().isNotEmpty ? _leaderController.text.trim() : widget.crew.leadStaffName,
                          vehicleCode: _vehicleCodeController.text.trim().isNotEmpty ? _vehicleCodeController.text.trim() : widget.crew.vehicleCode,
                          vehiclePlate: _vehiclePlateController.text.trim().isNotEmpty ? _vehiclePlateController.text.trim().toUpperCase() : widget.crew.vehiclePlate,
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

            // Botón opcional de eliminación / dar de baja
            if (widget.onDelete != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _handleDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                  label: const Text('Dar de baja cuadrilla', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
