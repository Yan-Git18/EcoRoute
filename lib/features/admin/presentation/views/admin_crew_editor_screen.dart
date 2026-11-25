import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../viewmodels/admin_reports_viewmodel.dart';

Future<void> openAdminCrewEditor(
  BuildContext context,
  WidgetRef ref, [
  MunicipalCrewEntity? crew,
]) async {
  final staff = ref.read(adminTeamStaffProvider).value;
  if (staff == null) return;
  final state = ref.read(adminReportsViewModelProvider);
  final viewModel = ref.read(adminReportsViewModelProvider.notifier);
  final sectors = {
    for (final team in state.teams)
      if (team.zone.trim().isNotEmpty) team.zone.trim(),
  }.toList()..sort();
  final vehicles = state.fleet
      .where(
        (truck) =>
            truck.vehicleOnly &&
            (truck.id == crew?.vehicleId ||
                (truck.assignedCrewId == null && truck.canDispatchVehicle)),
      )
      .toList();
  final changed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AdminCrewEditorScreen(
        crew: crew,
        staff: staff,
        vehicles: vehicles,
        sectors: sectors,
        onSave: (updated) async {
          final saved = await (crew == null
              ? viewModel.createCrew(updated)
              : viewModel.saveCrew(updated));
          if (!context.mounted || saved) return null;
          return ref.read(adminReportsViewModelProvider).errorMessage ??
              'No se pudo guardar el equipo.';
        },
      ),
    ),
  );
  if (context.mounted && changed == true) {
    ref.invalidate(adminTeamStaffProvider);
  }
}

class AdminCrewEditorScreen extends ConsumerStatefulWidget {
  const AdminCrewEditorScreen({
    super.key,
    this.crew,
    required this.staff,
    required this.vehicles,
    this.sectors = const [],
    required this.onSave,
  });

  final MunicipalCrewEntity? crew;
  final List<UserEntity> staff;
  final List<MunicipalCrewEntity> vehicles;
  final List<String> sectors;
  final Future<String?> Function(MunicipalCrewEntity) onSave;

  @override
  ConsumerState<AdminCrewEditorScreen> createState() =>
      _AdminCrewEditorScreenState();
}

class _AdminCrewEditorScreenState extends ConsumerState<AdminCrewEditorScreen> {
  static const _embeddedTruck = '@legacy';
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.crew?.name);
  late final _zone = TextEditingController(text: widget.crew?.zone);
  late final _people = {for (final person in widget.staff) person.id: person};
  late final _originalMembers = _initialMembers();
  late final _members = {..._originalMembers};
  late String? _leaderId = _initialLeader();
  late final String? _originalVehicle = _initialVehicle();
  late String? _vehicle = _originalVehicle;
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  bool _showStaff = false;
  bool _saving = false;

  List<String> _initialMembers() {
    final crew = widget.crew;
    if (crew == null) return [];
    if (crew.memberIds case final ids?) return ids;
    return [
      for (final person in widget.staff)
        if (person.teamId == crew.id) person.id,
    ];
  }

  String? _initialLeader() {
    final id = widget.crew?.effectiveLeaderId;
    return _members.contains(id) && _canLead(id) ? id : null;
  }

  bool _canLead(String? id) =>
      _people[id]?.isStaff == true && _people[id]?.isActive == true;

  bool get _validLeader => _members.contains(_leaderId) && _canLead(_leaderId);

  String? _initialVehicle() {
    final crew = widget.crew;
    if (crew == null) return null;
    return crew.vehicleId ??
        (crew.vehiclePlate.isEmpty ? null : _embeddedTruck);
  }

  bool get _keepsLegacyRoster =>
      widget.crew != null &&
      !MunicipalCrewEntity.isValidMemberCount(_originalMembers.length) &&
      _originalMembers.length == _members.length &&
      _originalMembers.every(_members.contains) &&
      _vehicle == _originalVehicle;

  bool get _validRoster =>
      MunicipalCrewEntity.isValidMemberCount(_members.length) ||
      _keepsLegacyRoster;
  bool get _hasRoom => _members.length < MunicipalCrewEntity.maxMembers;
  bool get _resourcesLocked => (widget.crew?.activeTasksCount ?? 0) > 0;
  MunicipalCrewEntity? get _truck =>
      widget.vehicles.where((unit) => unit.id == _vehicle).firstOrNull;

  @override
  void dispose() {
    _name.dispose();
    _zone.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _closeStaffSearch() {
    _searchFocus.unfocus();
    _search.clear();
    setState(() {
      _showStaff = false;
      _query = '';
    });
  }

  Future<void> _save() async {
    if (_saving || !_validRoster || !_validLeader) return;
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      await Scrollable.ensureVisible(
        invalid.first.context,
        duration: const Duration(milliseconds: 200),
        alignment: 0.15,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final original = widget.crew;
    final truck = _truck;
    final base =
        original ??
        const MunicipalCrewEntity(
          id: '',
          name: '',
          zone: '',
          leadStaffName: '',
          vehicleCode: '',
          vehiclePlate: '',
        );
    final updated = base.copyWith(
      name: _name.text.trim(),
      zone: _zone.text.trim(),
      leaderId: _leaderId,
      leadStaffName: _people[_leaderId]?.name,
      vehicleId: truck?.id,
      vehicleCode: truck?.vehicleCode,
      vehiclePlate: truck?.vehiclePlate,
      vehicleType: truck?.vehicleType,
      crewMembersCount: _members.length,
      memberIds: _members.toList(),
    );

    setState(() => _saving = true);
    final error = await widget.onSave(updated);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final crew = widget.crew;
    final availability = ref.watch(adminBusyStaffProvider);
    final busy = availability.value;
    final candidates = widget.staff.where(
      (person) =>
          person.isStaff &&
          person.isActive &&
          !_members.contains(person.id) &&
          (person.teamId?.isNotEmpty != true || person.teamId == crew?.id) &&
          busy != null &&
          !busy.contains(person.id),
    );
    final visible = candidates
        .where(
          (person) =>
              person.name.toLowerCase().contains(_query) ||
              person.email.toLowerCase().contains(_query),
        )
        .toList();
    final canChangeResources = !_resourcesLocked && !_saving;

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          centerTitle: true,
          leading: const CloseButton(),
          backgroundColor: const Color(0xFFF8FAFC),
          title: Text(crew == null ? 'Nuevo equipo' : 'Editar equipo'),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_resourcesLocked)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Finaliza el reporte activo para cambiar el camión o los integrantes.',
                        ),
                      ),
                    _EditorSection(
                      title: 'Información general',
                      children: [
                        TextFormField(
                          controller: _name,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del equipo',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) => (value?.trim().length ?? 0) < 3
                              ? 'Escribe al menos 3 caracteres.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _zone,
                          enabled: !_saving,
                          decoration: InputDecoration(
                            labelText: 'Sector',
                            suffixIcon: widget.sectors.isEmpty
                                ? null
                                : PopupMenuButton<String>(
                                    tooltip: 'Seleccionar sector',
                                    enabled: !_saving,
                                    icon: const Icon(Icons.expand_more),
                                    constraints: const BoxConstraints(
                                      minWidth: 160,
                                      maxWidth: 300,
                                      maxHeight: 240,
                                    ),
                                    onSelected: (sector) => _zone.text = sector,
                                    itemBuilder: (_) => [
                                      for (final sector in widget.sectors)
                                        PopupMenuItem(
                                          value: sector,
                                          child: Text(sector),
                                        ),
                                    ],
                                  ),
                          ),
                          validator: (value) => value?.trim().isNotEmpty != true
                              ? 'Escribe el sector del equipo.'
                              : null,
                        ),
                      ],
                    ),
                    _EditorSection(
                      title: 'Recursos asignados',
                      children: [
                        const Text('Camión'),
                        const SizedBox(height: 6),
                        FormField<String>(
                          initialValue: _vehicle,
                          validator: (id) => id == null && crew == null
                              ? 'Selecciona un camión disponible.'
                              : null,
                          builder: (field) => _TruckPicker(
                            selected:
                                _truck ?? (_vehicle == null ? null : crew),
                            vehicleId: _vehicle,
                            vehicles: widget.vehicles,
                            enabled:
                                canChangeResources &&
                                widget.vehicles.isNotEmpty,
                            errorText: field.errorText,
                            onSelected: (id) {
                              field.didChange(id);
                              setState(() => _vehicle = id);
                            },
                          ),
                        ),
                        if (widget.vehicles.isEmpty && !_resourcesLocked)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'No hay camiones disponibles en Flota Vehicular.',
                            ),
                          ),
                      ],
                    ),
                    _EditorSection(
                      title: 'Integrantes (${_members.length})',
                      children: [
                        if (_keepsLegacyRoster)
                          const Text(
                            'Puedes editar los datos generales. Para cambiar las asignaciones, el equipo debe tener entre 2 y 5 integrantes.',
                          )
                        else if (_members.length >
                            MunicipalCrewEntity.maxMembers)
                          Text(
                            'Retira ${_members.length - MunicipalCrewEntity.maxMembers} para guardar el equipo.',
                          )
                        else if (_hasRoom)
                          const Text('Selecciona entre 2 y 5 integrantes.')
                        else if (canChangeResources)
                          const Text(
                            'El equipo alcanzó el máximo de 5 integrantes.',
                          ),
                        const SizedBox(height: 10),
                        TapRegion(
                          onTapOutside: (_) {
                            if (_showStaff) _closeStaffSearch();
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _search,
                                focusNode: _searchFocus,
                                enabled: canChangeResources && _hasRoom,
                                decoration: const InputDecoration(
                                  hintText: 'Buscar integrantes',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onTap: () => setState(() => _showStaff = true),
                                onChanged: (value) => setState(() {
                                  _showStaff = true;
                                  _query = value.trim().toLowerCase();
                                }),
                              ),
                              if (_showStaff && canChangeResources)
                                Card(
                                  margin: const EdgeInsets.only(top: 4),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 208,
                                    ),
                                    child: availability.isLoading
                                        ? const LinearProgressIndicator()
                                        : availability.hasError
                                        ? TextButton(
                                            onPressed: () => ref.invalidate(
                                              adminBusyStaffProvider,
                                            ),
                                            child: const Text(
                                              'Volver a cargar disponibilidad',
                                            ),
                                          )
                                        : visible.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Text(
                                              'No se encontró personal disponible.',
                                            ),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            primary: false,
                                            padding: EdgeInsets.zero,
                                            itemCount: visible.length,
                                            itemBuilder: (context, index) {
                                              final person = visible[index];
                                              return ListTile(
                                                title: Text(person.name),
                                                subtitle: Text(person.email),
                                                onTap: () {
                                                  if (!_hasRoom) {
                                                    return;
                                                  }
                                                  _members.add(person.id);
                                                  _closeStaffSearch();
                                                },
                                              );
                                            },
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        RadioGroup<String>(
                          groupValue: _leaderId,
                          onChanged: (id) {
                            if (_saving ||
                                !_members.contains(id) ||
                                !_canLead(id)) {
                              return;
                            }
                            setState(() => _leaderId = id);
                          },
                          child: Column(
                            children: [
                              for (final id in _members) ...[
                                _CrewMemberRow(
                                  key: ValueKey(id),
                                  id: id,
                                  person: _people[id],
                                  isLeader: id == _leaderId,
                                  canLead: !_saving && _canLead(id),
                                  onRemove: canChangeResources
                                      ? () => setState(() {
                                          _members.remove(id);
                                          if (_leaderId == id) _leaderId = null;
                                        })
                                      : null,
                                ),
                                const Divider(
                                  height: 1,
                                  color: AppColors.border,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Selecciona un integrante como líder del equipo.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Material(
            color: Colors.white,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving || !_validRoster || !_validLeader
                          ? null
                          : _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(
                        _saving
                            ? 'Guardando…'
                            : crew == null
                            ? 'Crear equipo'
                            : 'Guardar cambios',
                      ),
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

class _CrewMemberRow extends StatelessWidget {
  const _CrewMemberRow({
    super.key,
    required this.id,
    required this.person,
    required this.isLeader,
    required this.canLead,
    required this.onRemove,
  });

  final String id;
  final UserEntity? person;
  final bool isLeader;
  final bool canLead;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final name = person?.name ?? 'Integrante sin perfil';
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (person case final member?)
                  Text(
                    member.email,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (isLeader) ...[
                  const SizedBox(height: 6),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      child: Text(
                        'Líder del equipo',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tooltip(
            message: 'Elegir a $name como líder',
            child: Radio<String>(
              value: id,
              enabled: canLead,
              activeColor: AppColors.primary,
            ),
          ),
          IconButton(
            tooltip: 'Quitar a ${person?.name ?? 'integrante'}',
            icon: const Icon(Icons.delete_outline),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _TruckPicker extends StatefulWidget {
  const _TruckPicker({
    required this.selected,
    required this.vehicleId,
    required this.vehicles,
    required this.enabled,
    required this.errorText,
    required this.onSelected,
  });

  final MunicipalCrewEntity? selected;
  final String? vehicleId;
  final List<MunicipalCrewEntity> vehicles;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String> onSelected;

  @override
  State<_TruckPicker> createState() => _TruckPickerState();
}

class _TruckPickerState extends State<_TruckPicker> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final truck = widget.selected;
    final colors = Theme.of(context).colorScheme;
    final showOptions = _open && widget.enabled;
    return TapRegion(
      onTapOutside: (_) {
        if (_open) setState(() => _open = false);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.enabled ? () => setState(() => _open = !_open) : null,
            child: InputDecorator(
              isFocused: showOptions || (truck != null && widget.enabled),
              decoration: InputDecoration(
                enabled: widget.enabled,
                errorText: widget.errorText,
                suffixIcon: Icon(
                  showOptions ? Icons.expand_less : Icons.expand_more,
                ),
              ),
              child: truck == null
                  ? const Text('Seleccionar camión')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            truck.vehicleCode,
                            truck.vehicleType,
                          ].where((value) => value.isNotEmpty).join(' · '),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (truck.vehiclePlate.isNotEmpty)
                          Text('Placa: ${truck.vehiclePlate}'),
                      ],
                    ),
            ),
          ),
          if (showOptions)
            Card(
              margin: const EdgeInsets.only(top: 4),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 4, 10, 6),
                      child: Text(
                        'Seleccionar camión',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 216),
                      child: ListView.builder(
                        shrinkWrap: true,
                        primary: false,
                        padding: EdgeInsets.zero,
                        itemCount: widget.vehicles.length,
                        itemBuilder: (context, index) {
                          final unit = widget.vehicles[index];
                          final selected = unit.id == widget.vehicleId;
                          return ListTile(
                            selected: selected,
                            selectedTileColor: colors.primaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            title: Text(unit.vehicleCode),
                            subtitle: Text(
                              '${unit.vehicleType}\nPlaca: ${unit.vehiclePlate}',
                            ),
                            isThreeLine: true,
                            trailing: Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: colors.primary,
                            ),
                            onTap: () {
                              setState(() => _open = false);
                              widget.onSelected(unit.id);
                            },
                          );
                        },
                      ),
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

class _EditorSection extends StatelessWidget {
  const _EditorSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
