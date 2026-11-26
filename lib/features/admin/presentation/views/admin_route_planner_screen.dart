import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/cajamarca_urban_zones.dart';
import '../../../routes/domain/collection_route.dart';
import '../../../routes/domain/optimize_collection_stops.dart';
import '../../../routes/presentation/collection_route_map.dart';
import '../../../routes/presentation/collection_route_providers.dart';
import '../../../routes/presentation/collection_route_summary.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../viewmodels/admin_route_providers.dart';
import 'admin_route_review_screen.dart';

class AdminRoutePlannerScreen extends ConsumerStatefulWidget {
  const AdminRoutePlannerScreen({super.key});

  @override
  ConsumerState<AdminRoutePlannerScreen> createState() =>
      _AdminRoutePlannerScreenState();
}

class _AdminRoutePlannerScreenState
    extends ConsumerState<AdminRoutePlannerScreen> {
  CajamarcaZone? _zone;
  final _selected = <String>{};
  Map<int, List<CollectionStop>>? _groups;
  var _nextGroup = 0;
  int? _focusedGroup;
  bool _showReportMap = false;
  final _estimates = <int, Future<CollectionRouteProposal>>{};

  void _estimate(int id) {
    final group = _groups![id];
    if (group == null) {
      _estimates.remove(id);
      return;
    }
    _estimates[id] = optimizeCollectionStops(
      group,
      ref.read(waypointRoutingProvider),
    );
  }

  Widget _footer(Widget button, {String? summary}) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null) Text(summary, textAlign: TextAlign.center),
        button,
      ],
    ),
  );

  void _backToReports() => setState(() {
    _groups = null;
    _focusedGroup = null;
    _estimates.clear();
  });

  void _toggle(CollectionStop stop) => setState(() {
    if (!_selected.add(stop.reportId)) _selected.remove(stop.reportId);
  });

  void _generate(List<CollectionStop> stops) {
    final proposals = ref.read(groupCollectionStopsProvider)(
      stops.where((stop) => _selected.contains(stop.reportId)),
    );
    setState(() {
      _nextGroup = 0;
      _groups = {for (final group in proposals) ++_nextGroup: group};
      _focusedGroup = _groups!.keys.firstOrNull;
      for (final id in _groups!.keys) {
        _estimate(id);
      }
    });
  }

  void _move(int source, int target, CollectionStop stop) {
    setState(() {
      final groups = _groups!;
      if (target == 0) target = ++_nextGroup;
      (groups[target] ??= []).add(stop);
      final sourceGroup = groups[source]!..remove(stop);
      if (sourceGroup.isEmpty) groups.remove(source);
      _focusedGroup = target;
      _estimate(source);
      _estimate(target);
    });
  }

  Future<void> _merge(int source, int target) async {
    final groups = _groups!;
    final stops = [...groups[target]!, ...groups[source]!];
    final combined = optimizeCollectionStops(
      stops,
      ref.read(waypointRoutingProvider),
    );
    final estimates = Future.wait([
      _estimates[target]!,
      _estimates[source]!,
      combined,
    ]);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Unir con la ruta $target?'),
        content: FutureBuilder(
          future: estimates,
          builder: (context, snapshot) {
            final proposals = snapshot.data;
            if (proposals == null) {
              return Text(
                snapshot.hasError
                    ? 'Recorrido por calles no disponible.'
                    : 'Calculando el recorrido combinado…',
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, proposal) in proposals.indexed) ...[
                  if (index > 0) const SizedBox(height: 12),
                  Text(
                    index == 2
                        ? 'Ruta combinada'
                        : 'Ruta ${index == 0 ? target : source}',
                  ),
                  RouteTravelEstimate(
                    stopCount: proposal.stops.length,
                    distanceMeters: proposal.road?.distanceMeters,
                    durationSeconds: proposal.road?.durationSeconds,
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unir rutas'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      groups[target] = stops;
      groups.remove(source);
      _focusedGroup = target;
      _estimates.remove(source);
      _estimates[target] = combined;
    });
  }

  Future<void> _review(int id, CollectionRouteProposal proposal) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminRouteReviewScreen(
          zone: _zone!,
          stops: proposal.stops,
          initialRouting: Future.value(proposal.road),
          initialName: 'Ruta $id · ${_zone!.name}',
        ),
      ),
    );
    if (!mounted || saved != true) return;
    setState(() {
      _groups!.remove(id);
      _estimates.remove(id);
      _focusedGroup = _groups!.keys.firstOrNull;
      _selected.removeAll(proposal.stops.map((stop) => stop.reportId));
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ruta planificada.')));
  }

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(eligibleRouteReportsProvider);
    final groups = _groups;
    final stops = available.asData?.value[_zone] ?? const <CollectionStop>[];
    final selectedCount = stops
        .where((stop) => _selected.contains(stop.reportId))
        .length;
    return PopScope(
      canPop: groups == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && groups != null) _backToReports();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            groups == null ? 'Planificar rutas' : 'Propuestas de rutas',
          ),
          leading: groups == null
              ? null
              : BackButton(onPressed: _backToReports),
        ),
        body: groups != null
            ? _proposalList(groups)
            : available.when(
                data: _selection,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: TextButton.icon(
                    onPressed: () => ref.invalidate(urbanReportsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar carga de reportes'),
                  ),
                ),
              ),
        bottomNavigationBar: groups == null
            ? stops.isEmpty
                  ? null
                  : _footer(
                      FilledButton.icon(
                        onPressed: selectedCount == 0
                            ? null
                            : () => _generate(stops),
                        icon: const Icon(Icons.alt_route),
                        label: const Text('Generar propuestas'),
                      ),
                      summary:
                          '$selectedCount de ${stops.length} seleccionados',
                    )
            : _proposalFooter(groups),
      ),
    );
  }

  Widget _selection(Map<CajamarcaZone, List<CollectionStop>> available) {
    final stops = available[_zone] ?? const <CollectionStop>[];
    final selectedCount = stops
        .where((stop) => _selected.contains(stop.reportId))
        .length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<CajamarcaZone>(
          initialValue: _zone,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Zona de trabajo'),
          items: [
            for (final zone in CajamarcaZone.values)
              DropdownMenuItem(
                value: zone,
                child: Text(
                  '${zone.name} · ${available[zone]?.length ?? 0} disponibles',
                ),
              ),
          ],
          onChanged: (zone) => setState(() {
            _zone = zone;
            _selected.clear();
          }),
        ),
        if (_zone == null)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text(
              'Elige una zona para consultar sus reportes disponibles.',
            ),
          )
        else if (stops.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text(
              'Esta zona no tiene reportes disponibles para planificar.',
            ),
          )
        else ...[
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: selectedCount == stops.length
                    ? null
                    : () => setState(() => _selected.addAll(stops.map((stop) => stop.reportId))),
                child: const Text('Seleccionar todos'),
              ),
              TextButton(
                onPressed: selectedCount == 0
                    ? null
                    : () => setState(_selected.clear),
                child: const Text('Limpiar selección'),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Lista'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Mapa'),
                  icon: Icon(Icons.map_outlined),
                ),
              ],
              selected: {_showReportMap},
              onSelectionChanged: (values) =>
                  setState(() => _showReportMap = values.single),
            ),
          ),
          const SizedBox(height: 12),
          if (_showReportMap)
            CollectionRouteMap(
              key: ValueKey(_zone),
              stops: stops,
              selectedReports: _selected,
              onStopTap: _toggle,
            )
          else
            for (final stop in stops)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _selected.contains(stop.reportId),
                onChanged: (_) => _toggle(stop),
                title: Text(
                  stop.address.isEmpty
                      ? 'Reporte ${stop.number}'
                      : stop.address,
                ),
                subtitle: Text(routeStopLabel(stop)),
              ),
        ],
      ],
    );
  }

  Widget _proposalList(Map<int, List<CollectionStop>> groups) {
    final canReview = groups.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_zone!.name, style: Theme.of(context).textTheme.titleLarge),
        if (canReview) ...[
          const SizedBox(height: 6),
          Text(
            '${groups.length} propuestas · ${groups.values.fold<int>(0, (count, group) => count + group.length)} reportes',
          ),
          const SizedBox(height: 12),
          if (_focusedGroup case final id?)
            FutureBuilder<CollectionRouteProposal>(
              future: _estimates[id],
              builder: (_, snapshot) {
                final proposal =
                    snapshot.connectionState == ConnectionState.done
                    ? snapshot.data
                    : null;
                final stops = proposal?.stops ?? groups[id]!;
                return CollectionRouteMap(
                  key: ObjectKey(stops),
                  stops: stops,
                  color: CollectionRouteMap.groupColor(
                    groups.keys.toList().indexOf(id),
                  ),
                  geometry: proposal?.road?.points ?? const [],
                  onStopTap: (stop) => _editStop(id, stop),
                );
              },
            ),
          const SizedBox(height: 12),
          for (final (index, entry) in groups.entries.indexed)
            _proposalCard(entry.key, entry.value, index, groups),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Confirmaste todas las propuestas.'),
          ),
      ],
    );
  }

  Widget _proposalFooter(Map<int, List<CollectionStop>> groups) {
    if (groups.isEmpty) {
      return _footer(
        FilledButton(
          onPressed: _backToReports,
          child: const Text('Planificar otra ruta'),
        ),
      );
    }
    final id = _focusedGroup!;
    return FutureBuilder<CollectionRouteProposal>(
      future: _estimates[id],
      builder: (_, snapshot) => _footer(
        FilledButton(
          onPressed: snapshot.connectionState != ConnectionState.done
              ? null
              : () => _review(
                  id,
                  snapshot.data ?? (stops: groups[id]!, road: null),
                ),
          child: Text('Revisar y asignar ruta $id'),
        ),
      ),
    );
  }

  Future<void> _editStop(int id, CollectionStop stop) async {
    final groups = _groups!;
    final options = [
      for (final entry in groups.entries)
        if (entry.key != id && entry.value.length < CollectionRoute.maxStops)
          (entry.key, 'Mover a ruta ${entry.key}'),
      if (groups[id]!.length > 1) (0, 'Mover a una ruta nueva'),
    ];
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text('Reporte ${stop.number}'),
              subtitle: Text(stop.address),
            ),
            for (final (target, label) in options)
              ListTile(
                leading: const Icon(Icons.alt_route),
                title: Text(label),
                onTap: () {
                  Navigator.of(context).pop();
                  _move(id, target, stop);
                },
              ),
            if (options.isEmpty)
              const ListTile(
                title: Text('No hay otro grupo con espacio para esta parada.'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _proposalCard(
    int id,
    List<CollectionStop> stops,
    int index,
    Map<int, List<CollectionStop>> groups,
  ) {
    final mergeTargets = groups.entries.where(
      (entry) =>
          entry.key != id &&
          entry.value.length + stops.length <= CollectionRoute.maxStops,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder<CollectionRouteProposal>(
        future: _estimates[id],
        builder: (_, snapshot) {
          final calculated = snapshot.connectionState == ConnectionState.done;
          final proposal = calculated ? snapshot.data : null;
          return ListTile(
            selected: _focusedGroup == id,
            onTap: () => setState(() => _focusedGroup = id),
            leading: Icon(
              Icons.alt_route,
              color: CollectionRouteMap.groupColor(index),
            ),
            title: Text('Ruta propuesta $id'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stops.length == 1 ? '1 parada' : '${stops.length} paradas',
                ),
                if (stops.length > 1)
                  if (calculated)
                    RouteTravelEstimate(
                      stopCount: stops.length,
                      distanceMeters: proposal?.road?.distanceMeters,
                      durationSeconds: proposal?.road?.durationSeconds,
                    )
                  else
                    const Text('Calculando recorrido…'),
              ],
            ),
            trailing: PopupMenuButton<int>(
              tooltip: 'Editar propuesta',
              onSelected: (target) => target == 0
                  ? _showStops(id, proposal?.stops ?? stops)
                  : _merge(id, target),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 0,
                  child: Text('Ver y mover paradas'),
                ),
                for (final entry in mergeTargets)
                  PopupMenuItem(
                    value: entry.key,
                    child: Text('Unir con ruta ${entry.key}'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showStops(int id, List<CollectionStop> stops) async {
    final stop = await showModalBottomSheet<CollectionStop>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final (index, stop) in stops.indexed)
              ListTile(
                leading: Text('${index + 1}'),
                title: Text(
                  stop.address.isEmpty
                      ? 'Reporte ${stop.number}'
                      : stop.address,
                ),
                subtitle: Text(routeStopLabel(stop)),
                trailing: const Icon(Icons.swap_horiz),
                onTap: () => Navigator.of(context).pop(stop),
              ),
          ],
        ),
      ),
    );
    if (mounted && stop != null) await _editStop(id, stop);
  }
}
