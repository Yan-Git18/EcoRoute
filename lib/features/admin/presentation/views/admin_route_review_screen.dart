import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/cajamarca_urban_zones.dart';
import '../../../../core/services/route_navigation_service.dart';
import '../../../routes/domain/collection_route.dart';
import '../../../routes/presentation/collection_route_map.dart';
import '../../../routes/presentation/collection_route_providers.dart';
import '../../../routes/presentation/collection_route_summary.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_route_schedule_form.dart';

class AdminRouteReviewScreen extends ConsumerStatefulWidget {
  const AdminRouteReviewScreen({
    super.key,
    required this.zone,
    required this.stops,
    required this.initialName,
    this.initialRouting,
  });

  final CajamarcaZone zone;
  final List<CollectionStop> stops;
  final String initialName;
  final Future<RouteInfoResult?>? initialRouting;

  @override
  ConsumerState<AdminRouteReviewScreen> createState() =>
      _AdminRouteReviewScreenState();
}

class _AdminRouteReviewScreenState
    extends ConsumerState<AdminRouteReviewScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _stops = List.of(widget.stops);
  late Future<RouteInfoResult?> _routing;

  @override
  void initState() {
    super.initState();
    final initialRouting = widget.initialRouting;
    if (initialRouting == null) {
      _calculate();
    } else {
      _routing = initialRouting;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _calculate() {
    _routing = ref
        .read(waypointRoutingProvider)
        .routeThrough(_stops.map((stop) => stop.location).toList());
  }

  void _move(int from, int to) {
    setState(() {
      _stops.insert(to, _stops.removeAt(from));
      _calculate();
    });
  }

  Future<void> _schedule(RouteInfoResult? road) async {
    if (!_form.currentState!.validate()) return;
    final draft = RouteDraft(
      name: _name.text,
      zone: widget.zone,
      stops: List.unmodifiable(_stops),
      geometry: road?.points ?? const [],
      distanceMeters: road?.distanceMeters,
      durationSeconds: road?.durationSeconds,
    );
    final repository = ref.read(collectionRouteRepositoryProvider);
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminRouteScheduleForm(
        onSave: (crewId, window) => repository.plan(draft, crewId, window),
      ),
    );
    if (!mounted || saved != true) return;
    ref.invalidate(urbanReportsProvider);
    ref.invalidate(adminReportsViewModelProvider);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar ruta')),
      body: FutureBuilder<RouteInfoResult?>(
        future: _routing,
        builder: (context, snapshot) {
          final calculating = snapshot.connectionState != ConnectionState.done;
          final road = calculating ? null : snapshot.data;
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.zone.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la ruta',
                  ),
                  validator: (value) => value?.trim().isNotEmpty == true
                      ? null
                      : 'Escribe un nombre.',
                ),
                CollectionRouteMap(
                  key: ObjectKey(road),
                  stops: _stops,
                  geometry: road?.points ?? const [],
                ),
                const SizedBox(height: 8),
                if (calculating)
                  const LinearProgressIndicator()
                else
                  RouteTravelEstimate(
                    stopCount: _stops.length,
                    distanceMeters: road?.distanceMeters,
                    durationSeconds: road?.durationSeconds,
                  ),
                const SizedBox(height: 12),
                Text(
                  'Orden de las paradas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final (index, stop) in _stops.indexed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(
                      stop.address.isEmpty
                          ? 'Reporte ${stop.number}'
                          : stop.address,
                    ),
                    subtitle: Text(routeStopLabel(stop)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Subir parada',
                          onPressed: index > 0
                              ? () => _move(index, index - 1)
                              : null,
                          icon: const Icon(Icons.keyboard_arrow_up),
                        ),
                        IconButton(
                          tooltip: 'Bajar parada',
                          onPressed: index < _stops.length - 1
                              ? () => _move(index, index + 1)
                              : null,
                          icon: const Icon(Icons.keyboard_arrow_down),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<RouteInfoResult?>(
        future: _routing,
        builder: (context, snapshot) => SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: snapshot.connectionState == ConnectionState.done
                ? () => _schedule(snapshot.data)
                : null,
            icon: const Icon(Icons.groups_outlined),
            label: const Text('Asignar y programar'),
          ),
        ),
      ),
    );
  }
}
