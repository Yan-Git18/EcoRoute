import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/media_image.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../viewmodels/admin_reports_viewmodel.dart';

class AdminAssignCrewModal extends ConsumerStatefulWidget {
  const AdminAssignCrewModal({
    super.key,
    required this.report,
    required this.adminId,
    required this.adminName,
  });

  final ReportEntity report;
  final String adminId;
  final String adminName;

  static Future<bool?> show({
    required BuildContext context,
    required ReportEntity report,
    required String adminId,
    required String adminName,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminAssignCrewModal(
          report: report,
          adminId: adminId,
          adminName: adminName,
        ),
      ),
    );
  }

  @override
  ConsumerState<AdminAssignCrewModal> createState() =>
      _AdminAssignCrewModalState();
}

class _AdminAssignCrewModalState extends ConsumerState<AdminAssignCrewModal> {
  static const _green = Color(0xFF047857);
  final _search = TextEditingController();
  final _instructions = TextEditingController();
  final _selectedStaff = <String>{};
  String? _selectedTeamId;
  String? _submissionError;
  bool _showTeams = false;
  bool _reviewing = false;

  @override
  void dispose() {
    _search.dispose();
    _instructions.dispose();
    super.dispose();
  }

  void _showReview(bool reviewing) {
    FocusScope.of(context).unfocus();
    setState(() {
      _reviewing = reviewing;
      _submissionError = null;
    });
  }

  void _reloadResources() {
    ref.invalidate(adminTeamStaffProvider);
    ref.invalidate(adminBusyStaffProvider);
    ref.read(adminReportsViewModelProvider.notifier).refresh();
  }

  Future<void> _submit(MunicipalCrewEntity? team) async {
    FocusScope.of(context).unfocus();
    setState(() => _submissionError = null);
    final notifier = ref.read(adminReportsViewModelProvider.notifier);
    final saved = await notifier.assignReport(
      reportId: widget.report.id,
      adminId: widget.adminId,
      adminName: widget.adminName,
      crew: team,
      staffIds: _showTeams ? const [] : _selectedStaff.toList(),
      instructions: _instructions.text.trim(),
    );
    if (!mounted) return;
    if (saved) {
      ref.invalidate(adminBusyStaffProvider);
      Navigator.of(context).pop(true);
    } else {
      final error = ref.read(adminReportsViewModelProvider).errorMessage;
      setState(() {
        _submissionError = error ?? 'No se pudo completar la asignación.';
      });
      _reloadResources();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportsViewModelProvider);
    final staff = ref.watch(adminTeamStaffProvider);
    final busy = ref.watch(adminBusyStaffProvider);
    final report = widget.report;
    final query = _search.text.trim().toLowerCase();
    final people = staff.value ?? const <UserEntity>[];
    final busyIds = (busy.value ?? const <String>{}).difference(
      widget.report.assignedStaffIds.toSet(),
    );
    final individual = people.where(
      (person) => person.teamId?.isNotEmpty != true,
    );
    bool isAvailable(UserEntity person) =>
        person.isActive && !busyIds.contains(person.id);
    final teams = state.teams.where(
      (team) =>
          team.canDispatch &&
          people.any(
            (person) =>
                person.id == team.effectiveLeaderId &&
                person.isActive &&
                person.teamId == team.id,
          ) &&
          people
              .where((person) => person.teamId == team.id)
              .every(
                (person) => person.isActive && !busyIds.contains(person.id),
              ),
    );
    final loading =
        staff.isLoading || busy.isLoading || (_showTeams && state.isLoading);
    final failed =
        staff.hasError ||
        busy.hasError ||
        (_showTeams && state.crewsLoadFailed);
    final selectedTeam = _showTeams
        ? teams.where((team) => team.id == _selectedTeamId).firstOrNull
        : null;
    final selectedPeople = _showTeams
        ? const <UserEntity>[]
        : individual
              .where((person) => _selectedStaff.contains(person.id))
              .toList();
    final selectionAvailable = _showTeams
        ? selectedTeam != null
        : _selectedStaff.isNotEmpty &&
              selectedPeople.length == _selectedStaff.length &&
              selectedPeople.every(isAvailable);
    final hasSelection = _showTeams
        ? _selectedTeamId != null
        : _selectedStaff.isNotEmpty;
    final canContinue =
        !state.isAssigning && !loading && !failed && selectionAvailable;
    final options = <Widget>[];
    if (!_reviewing && !loading && !failed) {
      if (_showTeams) {
        for (final team in teams) {
          final members = people
              .where((person) => person.teamId == team.id)
              .toList();
          final names = members.map((person) => person.name).join(', ');
          final truck = '${team.vehicleCode} · ${team.vehiclePlate}';
          if (!'${team.name} $names $truck'.toLowerCase().contains(query)) {
            continue;
          }
          options.add(
            _resource(
              title: team.name,
              subtitle: '${members.length} integrantes · $truck\n$names',
              avatar: const CircleAvatar(
                backgroundColor: Color(0xFFE0F2EC),
                foregroundColor: _green,
                child: Icon(Icons.groups_outlined),
              ),
              selected: _selectedTeamId == team.id,
              onTap: () => setState(
                () => _selectedTeamId = _selectedTeamId == team.id
                    ? null
                    : team.id,
              ),
            ),
          );
        }
      } else {
        for (final person in individual.where(
          (person) =>
              '${person.name} ${person.email}'.toLowerCase().contains(query),
        )) {
          final available = isAvailable(person);
          options.add(
            _resource(
              title: person.name,
              subtitle: !person.isActive
                  ? 'Cuenta inactiva'
                  : (available ? 'Disponible' : 'Con reporte activo'),
              avatar: SizedBox.square(
                dimension: 44,
                child: ClipOval(
                  child: MediaImage(
                    location: person.photoUrl,
                    placeholder: const ColoredBox(
                      color: Color(0xFFE0F2EC),
                      child: Icon(Icons.person_outline, color: _green),
                    ),
                  ),
                ),
              ),
              selected: _selectedStaff.contains(person.id),
              onTap: available
                  ? () => setState(() {
                      if (!_selectedStaff.remove(person.id)) {
                        _selectedStaff.add(person.id);
                      }
                    })
                  : null,
            ),
          );
        }
      }
    }

    return PopScope(
      canPop: !state.isAssigning && !_reviewing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _reviewing && !state.isAssigning) _showReview(false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Asignar Personal'),
          leading: _reviewing && !state.isAssigning
              ? BackButton(onPressed: () => _showReview(false))
              : null,
          backgroundColor: Colors.white,
        ),
        body: ListView(
          key: ValueKey(_reviewing),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.square(
                  dimension: 66,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MediaImage(
                      location: report.imageUrls.firstOrNull,
                      placeholder: const ColoredBox(
                        color: Color(0xFFE0F2EC),
                        child: Icon(Icons.image_outlined, color: _green),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.reportNumber,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        report.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (report.address.trim().isNotEmpty)
                        Text(
                          report.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (report.description.trim().isNotEmpty)
                        Text(
                          report.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_reviewing) ...[
              Text(
                'Paso 1 de 2 · Selecciona personal',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? _green
                        : const Color(0xFFF8FAFC),
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? Colors.white
                        : const Color(0xFF334155),
                  ),
                ),
                segments: const [
                  ButtonSegment(value: false, label: Text('Personal')),
                  ButtonSegment(value: true, label: Text('Equipos')),
                ],
                selected: {_showTeams},
                onSelectionChanged: state.isAssigning
                    ? null
                    : (values) => setState(() {
                        _showTeams = values.single;
                        _search.clear();
                      }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: _showTeams ? 'Buscar equipos…' : 'Buscar personal…',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (failed)
                TextButton.icon(
                  onPressed: _reloadResources,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Volver a cargar los recursos'),
                )
              else if (options.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    _showTeams
                        ? 'No hay equipos disponibles.'
                        : 'No se encontró personal sin equipo.',
                  ),
                )
              else
                ...options,
              if (!loading && !failed && hasSelection && !selectionAvailable)
                TextButton(
                  onPressed: () => setState(() {
                    if (_showTeams) {
                      _selectedTeamId = null;
                    } else {
                      _selectedStaff.retainAll(
                        selectedPeople
                            .where(isAvailable)
                            .map((person) => person.id),
                      );
                    }
                  }),
                  child: const Text('Quitar selecciones no disponibles'),
                ),
            ] else ...[
              Text(
                'Paso 2 de 2 · Instrucciones',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _showTeams ? 'Equipo seleccionado' : 'Personal seleccionado',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                _showTeams
                    ? selectedTeam?.name ?? 'Equipo no disponible'
                    : selectedPeople.map((person) => person.name).join(', '),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instructions,
                enabled: !state.isAssigning,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Instrucciones (opcional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (failed)
                TextButton(
                  onPressed: _reloadResources,
                  child: const Text('Volver a cargar los recursos'),
                )
              else if (!loading && !selectionAvailable)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Vuelve al primer paso para revisar la disponibilidad.',
                  ),
                ),
            ],
            if (_submissionError case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: !canContinue
                  ? null
                  : _reviewing
                  ? () => _submit(selectedTeam)
                  : () => _showReview(true),
              child: Text(
                state.isAssigning
                    ? 'Asignando…'
                    : _reviewing
                    ? 'Confirmar asignación'
                    : 'Continuar',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resource({
    required String title,
    required String subtitle,
    required Widget avatar,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return Column(
      children: [
        Semantics(
          checked: selected,
          child: ListTile(
            enabled:
                onTap != null &&
                !ref.read(adminReportsViewModelProvider).isAssigning,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            leading: avatar,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(subtitle),
            trailing: Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? _green : const Color(0xFF94A3B8),
            ),
            onTap: onTap,
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
      ],
    );
  }
}
