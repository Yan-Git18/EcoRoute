import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/domain/collection_route.dart';
import '../../../routes/presentation/collection_route_providers.dart';
import '../viewmodels/admin_route_providers.dart';

typedef RouteScheduleAction =
    Future<void> Function(String crewId, RouteWindow window);

class AdminRouteScheduleForm extends ConsumerStatefulWidget {
  const AdminRouteScheduleForm({super.key, required this.onSave, this.route});

  final RouteScheduleAction onSave;
  final CollectionRoute? route;

  @override
  ConsumerState<AdminRouteScheduleForm> createState() =>
      _AdminRouteScheduleFormState();
}

class _AdminRouteScheduleFormState
    extends ConsumerState<AdminRouteScheduleForm> {
  late String? _crewId = widget.route?.crewId;
  late DateTime _start = widget.route?.window.start ?? DateTime.now();
  late DateTime _end =
      widget.route?.window.end ?? _start.add(const Duration(hours: 1));
  String? _error;
  bool _saving = false;

  Future<void> _pickDateTime({required bool start}) async {
    final current = start ? _start : _end;
    final today = DateUtils.dateOnly(DateTime.now());
    final day = await showDatePicker(
      context: context,
      initialDate: current.isBefore(today) ? today : current,
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (!mounted || day == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!mounted || time == null) return;
    final value = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        if (!_end.isAfter(value)) _end = value.add(_end.difference(_start));
        _start = value;
      } else {
        _end = value;
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    final crewId = _crewId;
    if (_saving || crewId == null) return;
    final window = RouteWindow(_start, _end);
    if (!window.isValid || !_end.isAfter(DateTime.now())) {
      setState(
        () => _error =
            'Selecciona un horario vigente con el fin después del inicio.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(crewId, window);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = collectionRouteError(error);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final crews = ref.watch(routeCrewsProvider);
    final routes =
        ref.watch(collectionRoutesProvider(null)).asData?.value ??
        const <CollectionRoute>[];
    final window = RouteWindow(_start, _end);
    final now = DateTime.now();
    final conflictIds = {
      for (final route in routes)
        if (route.id != widget.route?.id &&
            ((route.status == CollectionRouteStatus.planned &&
                    route.window.overlaps(window)) ||
                (route.status == CollectionRouteStatus.inProgress &&
                    (route.window.overlaps(window) ||
                        !window.start.isAfter(now)))))
          route.crewId,
    };
    final selectedCrew = _crewId;
    final canSave =
        !_saving &&
        !conflictIds.contains(selectedCrew) &&
        crews.asData?.value.any((crew) => crew.id == selectedCrew) == true;
    final localizations = MaterialLocalizations.of(context);
    String label(DateTime date) =>
        '${localizations.formatShortDate(date)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
    final isEditing = widget.route != null;

    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(isEditing ? 'Editar planificación' : 'Asignar y programar'),
        scrollable: true,
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              crews.when(
                data: (data) {
                  if (data.isEmpty) {
                    return const Text(
                      'No hay equipos con líder y camión disponible.',
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: data.any((crew) => crew.id == _crewId)
                        ? _crewId
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Equipo'),
                    items: [
                      for (final crew in data)
                        DropdownMenuItem(
                          value: crew.id,
                          enabled: !conflictIds.contains(crew.id),
                          child: Text(
                            conflictIds.contains(crew.id)
                                ? '${crew.name} · Horario ocupado'
                                : '${crew.name} · ${crew.vehiclePlate}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (id) => setState(() {
                            _crewId = id;
                            _error = null;
                          }),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => TextButton(
                  onPressed: () => ref.invalidate(routeCrewsProvider),
                  child: const Text('Reintentar carga de equipos'),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Inicio previsto'),
                subtitle: Text(label(_start)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: _saving ? null : () => _pickDateTime(start: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fin previsto'),
                subtitle: Text(label(_end)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: _saving ? null : () => _pickDateTime(start: false),
              ),
              if (_error case final error?)
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (conflictIds.contains(selectedCrew))
                const Text(
                  'El equipo está ocupado en ese horario. Elige otro equipo u horario.',
                ),
              if (_saving) const LinearProgressIndicator(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: canSave ? _save : null,
            child: Text(
              isEditing ? 'Guardar cambios' : 'Confirmar planificación',
            ),
          ),
        ],
      ),
    );
  }
}
