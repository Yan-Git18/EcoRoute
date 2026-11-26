import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../../routes/domain/collection_route.dart';
import '../../../routes/presentation/collection_route_providers.dart';
import '../../../routes/presentation/collection_route_summary.dart';
import '../viewmodels/staff_home_viewmodel.dart';
import '../viewmodels/staff_operations_providers.dart';
import 'staff_route_map_screen.dart';
import '../widgets/staff_bottom_nav_bar.dart';
import '../widgets/staff_complete_task_sheet.dart';

class StaffCollectionRoutesScreen extends ConsumerWidget {
  const StaffCollectionRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(staffCollectionRoutesProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis rutas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Asignadas'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        bottomNavigationBar: const StaffBottomNavBar(currentIndex: 3),
        body: routes.when(
          data: (data) => TabBarView(
            children: [
              _list(context, [
                ...data.where(
                  (route) => route.status == CollectionRouteStatus.inProgress,
                ),
                ...data.where(
                  (route) => route.status == CollectionRouteStatus.planned,
                ),
              ], 'Tu equipo no tiene rutas asignadas.'),
              _list(
                context,
                data.reversed.where(
                  (route) =>
                      route.status == CollectionRouteStatus.completed ||
                      route.status == CollectionRouteStatus.cancelled,
                ),
                'Todavía no hay rutas en el historial.',
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text(collectionRouteReadError(error))),
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    Iterable<CollectionRoute> routes,
    String emptyLabel,
  ) {
    if (routes.isEmpty) return Center(child: Text(emptyLabel));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final route in routes)
          Card(
            child: ListTile(
              leading: const Icon(Icons.alt_route),
              title: Text(route.name),
              subtitle: Text(
                '${route.status.label} · ${route.completedStops}/${route.stops.length} paradas\n'
                '${routeWindowLabel(context, route.window)}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => StaffCollectionRouteScreen.open(context, route.id),
            ),
          ),
      ],
    );
  }
}

class StaffCollectionRouteScreen extends ConsumerStatefulWidget {
  const StaffCollectionRouteScreen({super.key, required this.id});

  final String id;

  static Future<void> open(BuildContext context, String id) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => StaffCollectionRouteScreen(id: id)),
      );

  @override
  ConsumerState<StaffCollectionRouteScreen> createState() =>
      _StaffCollectionRouteScreenState();
}

class _StaffCollectionRouteScreenState
    extends ConsumerState<StaffCollectionRouteScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(collectionRouteError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _attend(CollectionStop stop) async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    final result = await ref.read(updateTaskStatusUseCaseProvider)(
      taskId: stop.reportId,
      staffId: user.id,
      staffName: user.name,
      newStatus: ReportStatus.inProgress,
    );
    result.fold(
      onSuccess: (_) {},
      onFailure: (failure) => throw ServerException(message: failure.message),
    );
    if (mounted) {
      await ref
          .read(staffHomeViewModelProvider.notifier)
          .loadTasks(showLoading: false);
    }
  }

  Future<void> _skip(CollectionStop stop) async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RouteIncidentDialog(),
    );
    if (reason == null || !mounted) return;
    await _run(() async {
      await ref
          .read(collectionRouteRepositoryProvider)
          .skipStop(
            widget.id,
            stop.reportId,
            reason: reason,
            staffId: user.id,
            staffName: user.name,
          );
      if (!mounted) return;
      await ref
          .read(staffHomeViewModelProvider.notifier)
          .loadTasks(showLoading: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final route = ref.watch(collectionRouteProvider(widget.id));
    final data = route.asData?.value;
    final active = data?.status == CollectionRouteStatus.inProgress;
    final stop = active ? data?.nextStop : null;
    final isLeader =
        data != null && ref.watch(staffCanManageTaskProvider(data.crewId));
    final assignedTask = stop == null
        ? null
        : ref.watch(
            staffHomeViewModelProvider.select(
              (state) => state.tasks
                  .where(
                    (task) => task.isInProgress && task.id == stop.reportId,
                  )
                  .firstOrNull,
            ),
          );
    final planned = data?.status == CollectionRouteStatus.planned;
    final canManagePlanned = planned && isLeader;
    final clock = canManagePlanned
        ? ref.watch(staffShiftClockProvider).asData?.value
        : null;
    final canStart =
        canManagePlanned &&
        !(clock ?? DateTime.now()).isBefore(data.window.start);
    return Scaffold(
      appBar: AppBar(title: const Text('Ruta asignada')),
      body: route.when(
        data: (data) => data == null
            ? const Center(child: Text('La ruta ya no está disponible.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [CollectionRouteSummary(route: data)],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(collectionRouteReadError(error))),
      ),
      bottomNavigationBar: !canManagePlanned && stop == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_busy) const LinearProgressIndicator(),
                  if (canManagePlanned)
                    FilledButton.icon(
                      onPressed: _busy || !canStart
                          ? null
                          : () => _run(
                              () => ref
                                  .read(collectionRouteRepositoryProvider)
                                  .start(widget.id),
                            ),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        canStart
                            ? 'Iniciar ruta'
                            : 'Disponible desde el horario programado',
                      ),
                    ),
                  if (stop != null) ...[
                    OutlinedButton.icon(
                      onPressed: () =>
                          StaffRouteMapScreen.openNextStop(context, widget.id),
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text('Ir a la siguiente parada'),
                    ),
                    if (isLeader)
                      FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : assignedTask == null
                            ? () => _run(() => _attend(stop))
                            : () => StaffCompleteTaskSheet.show(
                                context,
                                assignedTask,
                              ),
                        icon: Icon(
                          assignedTask == null ? Icons.play_arrow : Icons.check,
                        ),
                        label: Text(
                          assignedTask == null
                              ? 'Iniciar atención'
                              : 'Registrar atención',
                        ),
                      ),
                    if (isLeader)
                      TextButton(
                        onPressed: _busy ? null : () => _skip(stop),
                        child: const Text('Reportar parada no atendida'),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _RouteIncidentDialog extends StatefulWidget {
  const _RouteIncidentDialog();

  @override
  State<_RouteIncidentDialog> createState() => _RouteIncidentDialogState();
}

class _RouteIncidentDialogState extends State<_RouteIncidentDialog> {
  final _form = GlobalKey<FormState>();
  String _reason = '';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Parada no atendida'),
    content: Form(
      key: _form,
      child: TextFormField(
        autofocus: true,
        maxLength: 300,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Motivo',
          helperText: 'El reporte quedará disponible para otra asignación.',
          helperMaxLines: 2,
        ),
        onChanged: (value) => _reason = value.trim(),
        validator: (_) => _reason.isEmpty ? 'Escribe un motivo.' : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.of(context).pop(_reason);
          }
        },
        child: const Text('Registrar'),
      ),
    ],
  );
}
