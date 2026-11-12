import 'package:flutter/material.dart';
import '../../domain/entities/municipal_crew_entity.dart';

/// Modal bottom sheet para dar de alta una nueva cuadrilla municipal.
///
/// Ubicación: `lib/features/admin/presentation/widgets/admin_crew_create_modal.dart`
/// Capa: Presentation (Widgets Admin)
class AdminCrewCreateModal extends StatefulWidget {
  final Future<bool> Function(MunicipalCrewEntity crew) onConfirm;

  const AdminCrewCreateModal({
    super.key,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required Future<bool> Function(MunicipalCrewEntity crew) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdminCrewCreateModal(onConfirm: onConfirm),
    );
  }

  @override
  State<AdminCrewCreateModal> createState() => _AdminCrewCreateModalState();
}

class _AdminCrewCreateModalState extends State<AdminCrewCreateModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _zoneController = TextEditingController();
  final _leaderController = TextEditingController();
  final _vehicleCodeController = TextEditingController();
  final _vehiclePlateController = TextEditingController();

  String _selectedVehicleType = 'Camión Compactador 15m³';
  final MunicipalCrewStatus _selectedStatus = MunicipalCrewStatus.available;
  int _membersCount = 3;
  bool _isSaving = false;

  static const List<String> _vehicleTypes = [
    'Camión Compactador 15m³',
    'Furgón Barrendero Ligero',
    'Camión Recolector Urbano',
    'Camión Volquete Pesado',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _zoneController.dispose();
    _leaderController.dispose();
    _vehicleCodeController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newCrew = MunicipalCrewEntity(
      id: '', // Generado por Firestore o el DataSource
      name: _nameController.text.trim(),
      zone: _zoneController.text.trim(),
      leadStaffName: _leaderController.text.trim(),
      vehicleCode: _vehicleCodeController.text.trim(),
      vehiclePlate: _vehiclePlateController.text.trim().toUpperCase(),
      vehicleType: _selectedVehicleType,
      crewMembersCount: _membersCount,
      activeTasksCount: 0,
      isAvailable: _selectedStatus == MunicipalCrewStatus.available,
      status: _selectedStatus,
    );

    final success = await widget.onConfirm(newCrew);
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
      child: Form(
        key: _formKey,
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

              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A5835).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_business_rounded, color: Color(0xFF0A5835), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrar Nueva Cuadrilla',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Alta de unidad y personal en Cloud Firestore',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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

              // Nombre de la cuadrilla
              _buildInputLabel('Nombre de la Cuadrilla'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Ej. Cuadrilla Zona Este'),
                validator: (val) => (val == null || val.trim().length < 3)
                    ? 'Ingrese un nombre de al menos 3 caracteres.'
                    : null,
              ),
              const SizedBox(height: 14),

              // Sector o Zona
              _buildInputLabel('Sector o Zona de Cobertura'),
              TextFormField(
                controller: _zoneController,
                decoration: _inputDecoration('Ej. Sector 5 (Av. Javier Prado)'),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Especifique la zona asignada.'
                    : null,
              ),
              const SizedBox(height: 14),

              // Líder / Encargado
              _buildInputLabel('Líder o Personal Encargado'),
              TextFormField(
                controller: _leaderController,
                decoration: _inputDecoration('Ej. Carlos Mendoza'),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Especifique el nombre del líder de cuadrilla.'
                    : null,
              ),
              const SizedBox(height: 14),

              // Vehículo: Código y Placa en fila
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Código Unidad'),
                        TextFormField(
                          controller: _vehicleCodeController,
                          decoration: _inputDecoration('Ej. Camión #06'),
                          validator: (val) => (val == null || val.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Placa Vehicular'),
                        TextFormField(
                          controller: _vehiclePlateController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _inputDecoration('Ej. ECR-902'),
                          validator: (val) => (val == null || val.trim().length < 3)
                              ? 'Placa inválida'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Tipo de Vehículo
              _buildInputLabel('Tipo de Vehículo'),
              DropdownButtonFormField<String>(
                initialValue: _selectedVehicleType,
                decoration: _inputDecoration('Seleccione tipo'),
                items: _vehicleTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedVehicleType = val);
                },
              ),
              const SizedBox(height: 14),

              // Cantidad de miembros
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInputLabel('Número de Integrantes: $_membersCount'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF64748B)),
                        onPressed: _membersCount > 1
                            ? () => setState(() => _membersCount--)
                            : null,
                      ),
                      Text('$_membersCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0A5835)),
                        onPressed: _membersCount < 10
                            ? () => setState(() => _membersCount++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A5835),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Registrar Cuadrilla en Firestore',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
    );
  }
}
