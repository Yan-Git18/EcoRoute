import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../viewmodels/admin_reports_viewmodel.dart';

Future<void> openAdminVehicleEditor(
  BuildContext context, [
  MunicipalCrewEntity? vehicle,
]) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _AdminVehicleEditorScreen(vehicle: vehicle),
  ),
);

class _AdminVehicleEditorScreen extends ConsumerStatefulWidget {
  const _AdminVehicleEditorScreen({this.vehicle});

  final MunicipalCrewEntity? vehicle;

  @override
  ConsumerState<_AdminVehicleEditorScreen> createState() =>
      _AdminVehicleEditorScreenState();
}

class _AdminVehicleEditorScreenState
    extends ConsumerState<_AdminVehicleEditorScreen> {
  static const _vehicleTypes = [
    'Camión Compactador 15m³',
    'Furgón Barrendero Ligero',
    'Camión Recolector Urbano',
    'Camión Volquete Pesado',
  ];

  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.vehicle?.vehicleCode);
  late final _plate = TextEditingController(text: widget.vehicle?.vehiclePlate);
  late String? _type = switch (widget.vehicle?.vehicleType) {
    null => _vehicleTypes.first,
    '' => null,
    final type => type,
  };
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final code = _code.text.trim();
    final plate = _plate.text.trim().toUpperCase();
    final original = widget.vehicle;
    final vehicle =
        original?.copyWith(
          name: code,
          vehicleCode: code,
          vehiclePlate: plate,
          vehicleType: _type,
        ) ??
        MunicipalCrewEntity(
          id: '',
          name: code,
          zone: '',
          leadStaffName: MunicipalCrewEntity.unassignedDriver,
          vehicleCode: code,
          vehiclePlate: plate,
          vehicleType: _type!,
          vehicleOnly: true,
        );
    final viewModel = ref.read(adminReportsViewModelProvider.notifier);
    final saved = await (original == null
        ? viewModel.createCrew(vehicle)
        : viewModel.saveCrew(vehicle));
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
      final error = ref.read(adminReportsViewModelProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'No se pudo guardar el vehículo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = {..._vehicleTypes, if (_type case final type?) type};
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            icon: const CloseButtonIcon(),
          ),
          title: Text(
            widget.vehicle == null ? 'Nuevo vehículo' : 'Editar vehículo',
          ),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _code,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Nombre o código del vehículo',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value?.trim().length ?? 0) < 3
                        ? 'Escribe un nombre o código de al menos 3 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _plate,
                    enabled: !_saving,
                    decoration: const InputDecoration(labelText: 'Placa'),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) => (value?.trim().length ?? 0) < 3
                        ? 'Escribe una placa válida.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de vehículo',
                    ),
                    items: [
                      for (final type in types)
                        DropdownMenuItem(
                          value: type,
                          child: Text(type, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: _saving ? null : (value) => _type = value,
                    validator: (value) => value == null
                        ? 'Selecciona el tipo de vehículo.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving
                          ? 'Guardando…'
                          : widget.vehicle == null
                          ? 'Crear vehículo'
                          : 'Guardar cambios',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
