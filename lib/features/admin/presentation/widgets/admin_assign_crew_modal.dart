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
  MunicipalCrewEntity? _selectedTeam;
  late ReportPriority _priority = widget.report.priority;
  bool _showTeams = false;

  @override
  void dispose() {
    _search.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final notifier = ref.read(adminReportsViewModelProvider.notifier);
    final saved = await notifier.assignReport(
      reportId: widget.report.id,
      adminId: widget.adminId,
      adminName: widget.adminName,
      crew: _showTeams ? _selectedTeam : null,
      staffIds: _showTeams ? const [] : _selectedStaff.toList(),
      priority: _priority,
      instructions: _instructions.text.trim(),
    );
    if (!mounted) return;
    if (saved) {
      ref.invalidate(adminBusyStaffProvider);
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _selectedStaff.clear();
        _selectedTeam = null;
      });
      ref.invalidate(adminTeamStaffProvider);
      ref.invalidate(adminBusyStaffProvider);
      notifier.refresh();
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
      (person) =>
          person.teamId?.isNotEmpty != true &&
          '${person.name} ${person.email}'.toLowerCase().contains(query),
    );
    final teams = state.teams.where(
      (team) =>
          team.canDispatch &&
          people.any((person) => person.isActive && person.teamId == team.id) &&
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
    final options = <Widget>[];
    if (!loading && !failed) {
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
              selected: _selectedTeam?.id == team.id,
              onTap: () => setState(
                () =>
                    _selectedTeam = _selectedTeam?.id == team.id ? null : team,
              ),
            ),
          );
        }
      } else {
        for (final person in individual) {
          final available = person.isActive && !busyIds.contains(person.id);
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
      canPop: !state.isAssigning,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Asignar Personal'),
          backgroundColor: Colors.white,
        ),
        body: ListView(
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
                onPressed: () {
                  ref.invalidate(adminTeamStaffProvider);
                  ref.invalidate(adminBusyStaffProvider);
                  ref.read(adminReportsViewModelProvider.notifier).refresh();
                },
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
            if (state.errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ExpansionTile(
              title: const Text('Prioridad e instrucciones'),
              tilePadding: EdgeInsets.zero,
              children: [
                DropdownButtonFormField<ReportPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Prioridad'),
                  items: [
                    for (final priority in ReportPriority.values)
                      DropdownMenuItem(
                        value: priority,
                        child: Text(priority.label),
                      ),
                  ],
                  onChanged: state.isAssigning
                      ? null
                      : (priority) => setState(() => _priority = priority!),
                ),
                TextField(
                  controller: _instructions,
                  enabled: !state.isAssigning,
                  decoration: const InputDecoration(
                    labelText: 'Instrucciones operativas',
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed:
                state.isAssigning ||
                    loading ||
                    failed ||
                    (_showTeams
                        ? _selectedTeam == null
                        : _selectedStaff.isEmpty)
                ? null
                : _submit,
            child: Text(state.isAssigning ? 'Asignando…' : 'Asignar'),
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
