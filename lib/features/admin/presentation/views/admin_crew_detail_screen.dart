import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_crew_card.dart';
import 'admin_crew_editor_screen.dart';

final _activeReportsProvider = FutureProvider.autoDispose
    .family<List<ReportEntity>, String>((ref, crewId) async {
      final result = await ref
          .watch(adminRepositoryProvider)
          .getCrewActiveReports(crewId);
      return result.fold(
        onSuccess: (reports) => reports,
        onFailure: (failure) => throw failure.message,
      );
    });

class AdminCrewDetailScreen extends ConsumerStatefulWidget {
  const AdminCrewDetailScreen({super.key, required this.crewId});

  final String crewId;

  @override
  ConsumerState<AdminCrewDetailScreen> createState() =>
      _AdminCrewDetailScreenState();
}

class _AdminCrewDetailScreenState extends ConsumerState<AdminCrewDetailScreen> {
  bool _deleting = false;

  Future<void> _delete(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar equipo'),
        content: Text('¿Eliminar «$name» y liberar su camión e integrantes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _deleting = true);
    final deleted = await ref
        .read(adminReportsViewModelProvider.notifier)
        .deleteCrew(widget.crewId);
    if (!mounted) return;
    if (deleted) {
      ref.invalidate(adminTeamStaffProvider);
      Navigator.pop(context);
      return;
    }
    setState(() => _deleting = false);
    final message = ref.read(adminReportsViewModelProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'No se pudo eliminar el equipo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportsViewModelProvider);
    final staff = ref.watch(adminTeamStaffProvider);
    final crew = state.teams
        .where((crew) => crew.id == widget.crewId)
        .firstOrNull;
    if (crew == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del equipo')),
        body: Center(
          child: _deleting
              ? const CircularProgressIndicator()
              : const Text('El equipo ya no está disponible.'),
        ),
      );
    }

    final members =
        staff.value
            ?.where(
              (person) =>
                  crew.memberIds?.contains(person.id) ??
                  person.teamId == crew.id,
            )
            .toList() ??
        [];
    final activeReports = ref.watch(_activeReportsProvider(crew.id));
    ref.listen(
      adminReportsViewModelProvider.select(
        (state) => state.crews
            .where((item) => item.id == crew.id)
            .firstOrNull
            ?.activeTasksCount,
      ),
      (previous, next) {
        if (next != null) ref.invalidate(_activeReportsProvider(crew.id));
      },
    );
    final reports = activeReports.value ?? const [];
    final count = crew.crewMembersCount;
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_deleting,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          title: const Text('Detalle del equipo'),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Más acciones',
              enabled: !_deleting,
              onSelected: (_) => _delete(crew.name),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Eliminar equipo')),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              crew.name,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AdminCrewStatusLabel(crew.status, showIcon: true),
                Text(
                  count == 1 ? '· 1 integrante' : '· $count integrantes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailSection(
              title: 'Información del equipo',
              children: [
                for (final (index, (label, value)) in [
                  ('Camión', crew.vehicleCode),
                  ('Tipo de vehículo', crew.vehicleType),
                  ('Placa', crew.vehiclePlate),
                ].indexed) ...[
                  if (index > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: Text(
                            value.isEmpty ? 'Sin registrar' : value,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            _DetailSection(
              title: 'Integrantes ($count)',
              children: [
                if (staff.isLoading) const LinearProgressIndicator(),
                if (staff.hasError)
                  TextButton.icon(
                    onPressed: () => ref.invalidate(adminTeamStaffProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Volver a cargar integrantes'),
                  ),
                if (staff.hasValue && members.isEmpty)
                  const Text('No hay integrantes para mostrar.'),
                for (final (index, member) in members.indexed) ...[
                  if (index > 0) const Divider(height: 1, indent: 56),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: Text(
                        member.name
                            .trim()
                            .split(RegExp(r'\s+'))
                            .where((word) => word.isNotEmpty)
                            .take(2)
                            .map((word) => word.characters.first.toUpperCase())
                            .join(),
                      ),
                    ),
                    title: Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      member.id == crew.effectiveLeaderId
                          ? 'Líder del equipo'
                          : member.role.displayName,
                    ),
                  ),
                ],
              ],
            ),
            _DetailSection(
              title: 'Operación',
              children: [
                if (crew.activeTasksCount > 0)
                  Text(
                    crew.activeTasksCount == 1
                        ? '1 reporte activo'
                        : '${crew.activeTasksCount} reportes activos',
                  ),
                for (final report in reports)
                  _DetailField(
                    report.reportNumber,
                    '${report.categoryName} · ${report.status.label}',
                  ),
                if (activeReports.isLoading) const LinearProgressIndicator(),
                if (activeReports.hasError)
                  TextButton.icon(
                    onPressed: () =>
                        ref.invalidate(_activeReportsProvider(crew.id)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Volver a cargar reportes'),
                  ),
                if (crew.hasLocation)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _deleting
                          ? null
                          : () => context.push(
                              Uri(
                                path: RouteNames.adminLiveMap,
                                queryParameters: {'teamId': crew.id},
                              ).toString(),
                            ),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Ver en mapa'),
                    ),
                  ),
                _DetailField(
                  'Última actualización del equipo',
                  crew.updatedAt == null
                      ? 'Sin registrar'
                      : MaterialLocalizations.of(
                          context,
                        ).formatShortDate(crew.updatedAt!.toLocal()),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: FilledButton.icon(
            onPressed: staff.hasValue && !staff.isLoading && !_deleting
                ? () => openAdminCrewEditor(context, ref, crew)
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar equipo'),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: const Color(0xFFF6F7F9),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label\n',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
