import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../routes/domain/collection_route.dart';
import '../../../routes/presentation/collection_route_providers.dart';
import '../../../routes/presentation/collection_route_summary.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/admin_route_schedule_form.dart';

class AdminRoutesScreen extends ConsumerWidget {
  const AdminRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(collectionRoutesProvider(null));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rutas de recolección'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Planificadas'),
              Tab(text: 'En curso'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: routes.when(
          data: (data) => TabBarView(
            children: [
              _RouteList(
                routes: data.where(
                  (route) => route.status == CollectionRouteStatus.planned,
                ),
                emptyLabel: 'Aún no hay rutas planificadas.',
              ),
              _RouteList(
                routes: data.where(
                  (route) => route.status == CollectionRouteStatus.inProgress,
                ),
                emptyLabel: 'Ningún equipo está ejecutando una ruta.',
              ),
              _RouteList(
                routes: data.reversed.where(
                  (route) =>
                      route.status == CollectionRouteStatus.completed ||
                      route.status == CollectionRouteStatus.cancelled,
                ),
                emptyLabel: 'Aún no hay rutas finalizadas o canceladas.',
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    collectionRouteReadError(error),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(collectionRoutesProvider(null)),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: routes.hasValue
            ? FloatingActionButton.extended(
                onPressed: () => context.push(RouteNames.adminRoutePlanner),
                icon: const Icon(Icons.add),
                label: const Text('Planificar rutas'),
              )
            : null,
        bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3),
      ),
    );
  }
}

class _RouteList extends StatelessWidget {
  const _RouteList({required this.routes, required this.emptyLabel});

  final Iterable<CollectionRoute> routes;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) return Center(child: Text(emptyLabel));
    final items = routes.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final route = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.alt_route)),
            title: Text(route.name),
            subtitle: Text(
              '${route.zone.name} · ${route.crewName}\n'
              '${routeWindowLabel(context, route.window)}\n'
              '${route.completedStops}/${route.stops.length} paradas · ${route.status.label}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                context.push(RouteNames.adminCollectionRouteLocation(route.id)),
          ),
        );
      },
    );
  }
}

class AdminCollectionRouteScreen extends ConsumerStatefulWidget {
  const AdminCollectionRouteScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AdminCollectionRouteScreen> createState() =>
      _AdminCollectionRouteScreenState();
}

class _AdminCollectionRouteScreenState
    extends ConsumerState<AdminCollectionRouteScreen> {
  bool _busy = false;

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar ruta'),
        content: const Text(
          'Los reportes pendientes volverán a estar disponibles para asignación directa o para otra ruta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar ruta'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(collectionRouteRepositoryProvider).cancel(widget.id);
      if (!mounted) return;
      ref.invalidate(urbanReportsProvider);
      ref.invalidate(adminReportsViewModelProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(collectionRouteError(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reschedule(CollectionRoute route) {
    final repository = ref.read(collectionRouteRepositoryProvider);
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminRouteScheduleForm(
        route: route,
        onSave: (crewId, window) =>
            repository.reschedule(route.id, crewId, window),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = ref.watch(collectionRouteProvider(widget.id));
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.adminRoutes);
            }
          },
        ),
        title: const Text('Detalle de ruta'),
      ),
      body: route.when(
        data: (data) => data == null
            ? const Center(child: Text('No se encontró la ruta.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CollectionRouteSummary(
                    route: data,
                    onStopTap: (stop) => context.push(
                      RouteNames.adminReportLocation(stop.reportId),
                    ),
                  ),
                  if (data.status == CollectionRouteStatus.planned)
                    FilledButton(
                      onPressed: _busy ? null : () => _reschedule(data),
                      child: const Text('Editar planificación'),
                    ),
                  if (data.status == CollectionRouteStatus.planned ||
                      data.status == CollectionRouteStatus.inProgress)
                    OutlinedButton(
                      onPressed: _busy ? null : _cancel,
                      child: Text(_busy ? 'Cancelando…' : 'Cancelar ruta'),
                    ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(collectionRouteError(error))),
      ),
    );
  }
}
