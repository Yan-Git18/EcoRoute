import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../viewmodels/admin_reports_state.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_back_button.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/admin_crew_card.dart';
import '../widgets/admin_filter_carousel.dart';
import '../widgets/admin_load_notice.dart';
import 'admin_vehicle_editor_screen.dart';

class AdminFleetScreen extends ConsumerStatefulWidget {
  const AdminFleetScreen({super.key});

  @override
  ConsumerState<AdminFleetScreen> createState() => _AdminFleetScreenState();
}

class _AdminFleetScreenState extends ConsumerState<AdminFleetScreen> {
  MunicipalCrewStatus? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportsViewModelProvider);
    final viewModel = ref.read(adminReportsViewModelProvider.notifier);
    final vehicles = state.fleet
        .map((vehicle) => _FleetVehicle.fromState(vehicle, state))
        .where((vehicle) {
          return (_filter == null || vehicle.status == _filter) &&
              [
                vehicle.unit.vehicleCode,
                vehicle.unit.vehiclePlate,
                vehicle.unit.vehicleType,
                vehicle.driver,
                vehicle.team?.name ?? '',
              ].any((value) => value.toLowerCase().contains(_query));
        })
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AdminBackButton(),
        title: const Text('Flota Vehicular'),
        actions: [
          IconButton(
            tooltip: 'Actualizar flota',
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading ? null : viewModel.refresh,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 856),
          child: Column(
            children: [
              AdminLoadNotice(
                state: state,
                onRetry: viewModel.refresh,
                showReports: false,
              ),
              if (state.hasLoadedCrews) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Buscar vehículo o placa',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AdminFilterCarousel(
                    children: [
                      for (final (status, label) in [
                        (null, 'Todos'),
                        (MunicipalCrewStatus.available, 'Disponibles'),
                        (MunicipalCrewStatus.onRoute, 'En ruta'),
                        (MunicipalCrewStatus.maintenance, 'En taller'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: _filter == status,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _filter = status),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: viewModel.refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: vehicles.isEmpty ? 1 : vehicles.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (vehicles.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No hay vehículos que coincidan.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final vehicle = vehicles[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          child: ListTile(
                            leading: const Icon(Icons.local_shipping_outlined),
                            title: Text(vehicle.unit.vehicleCode),
                            subtitle: Text(vehicle.unit.vehiclePlate),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AdminCrewStatusLabel(vehicle.status),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => _VehicleDetailScreen(
                                  initialVehicle: vehicle.unit,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openAdminVehicleEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo vehículo'),
      ),
      bottomNavigationBar: const AdminBottomNavBar(),
    );
  }
}

class _FleetVehicle {
  const _FleetVehicle(this.unit, this.team);

  factory _FleetVehicle.fromState(
    MunicipalCrewEntity unit,
    AdminReportsState state,
  ) {
    final team = unit.vehicleOnly
        ? state.teams
              .where(
                (team) =>
                    team.id == unit.assignedCrewId && team.vehicleId == unit.id,
              )
              .firstOrNull
        : unit;
    return _FleetVehicle(unit, team);
  }

  final MunicipalCrewEntity unit;
  final MunicipalCrewEntity? team;

  String get driver {
    final name = team?.leadStaffName.trim();
    return team?.effectiveLeaderId != null && name?.isNotEmpty == true
        ? name!
        : MunicipalCrewEntity.unassignedDriver;
  }

  MunicipalCrewStatus get status {
    if (unit.status == MunicipalCrewStatus.maintenance) return unit.status;
    return team?.status == MunicipalCrewStatus.onRoute
        ? MunicipalCrewStatus.onRoute
        : unit.status;
  }

  bool get hasActiveReport => (team?.activeTasksCount ?? 0) > 0;
  bool get isLinked => unit.assignedCrewId != null || team != null;
}

class _VehicleDetailScreen extends ConsumerStatefulWidget {
  const _VehicleDetailScreen({required this.initialVehicle});

  final MunicipalCrewEntity initialVehicle;

  @override
  ConsumerState<_VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<_VehicleDetailScreen> {
  bool _busy = false;

  Future<void> _setMaintenance(MunicipalCrewEntity unit) async {
    setState(() => _busy = true);
    final returning = unit.status == MunicipalCrewStatus.maintenance;
    final saved = await ref
        .read(adminReportsViewModelProvider.notifier)
        .saveCrew(
          unit.copyWith(
            status: returning
                ? MunicipalCrewStatus.available
                : MunicipalCrewStatus.maintenance,
            isAvailable: returning,
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!saved) _showError('No se pudo actualizar el estado del vehículo.');
  }

  Future<void> _delete(MunicipalCrewEntity unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text(
          '¿Eliminar ${unit.vehicleCode} con placa ${unit.vehiclePlate}?',
        ),
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
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final deleted = await ref
        .read(adminReportsViewModelProvider.notifier)
        .deleteVehicle(unit.id);
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
      _showError('No se pudo eliminar el vehículo.');
    }
  }

  void _showError(String fallback) {
    final message = ref.read(adminReportsViewModelProvider).errorMessage;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? fallback)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportsViewModelProvider);
    final original = widget.initialVehicle;
    final unit = state.fleet
        .where(
          (unit) =>
              unit.id == original.id &&
              unit.vehicleOnly == original.vehicleOnly,
        )
        .firstOrNull;
    final vehicle = unit == null ? null : _FleetVehicle.fromState(unit, state);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detalle del vehículo')),
      body: vehicle == null
          ? Center(
              child: Text(
                _busy
                    ? 'Eliminando vehículo…'
                    : 'El vehículo ya no está disponible.',
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.local_shipping_outlined),
                            title: Text(
                              vehicle.unit.vehicleCode,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            subtitle: Text(vehicle.unit.vehiclePlate),
                            trailing: AdminCrewStatusLabel(vehicle.status),
                          ),
                          const Divider(height: 1),
                          _VehicleInfo(
                            label: 'Tipo de vehículo',
                            value: vehicle.unit.vehicleType,
                          ),
                          _VehicleInfo(
                            label: 'Conductor',
                            value: vehicle.driver,
                          ),
                          _VehicleInfo(
                            label: 'Equipo asignado',
                            value: vehicle.team?.name ?? 'Sin equipo',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (vehicle.unit.vehicleOnly) ...[
                      FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () =>
                                  openAdminVehicleEditor(context, vehicle.unit),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar vehículo'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed:
                            _busy ||
                                (vehicle.hasActiveReport &&
                                    vehicle.status !=
                                        MunicipalCrewStatus.maintenance)
                            ? null
                            : () => _setMaintenance(vehicle.unit),
                        icon: const Icon(Icons.build_outlined),
                        label: Text(
                          vehicle.status == MunicipalCrewStatus.maintenance
                              ? 'Registrar salida del taller'
                              : 'Enviar al taller',
                        ),
                      ),
                      if (vehicle.hasActiveReport &&
                          vehicle.status != MunicipalCrewStatus.maintenance)
                        const Text(
                          'Finaliza el reporte activo para enviar el vehículo al taller.',
                        ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _busy || vehicle.isLinked
                            ? null
                            : () => _delete(vehicle.unit),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar vehículo'),
                      ),
                      if (vehicle.isLinked)
                        const Text(
                          'Cambia el vehículo del equipo antes de eliminarlo.',
                        ),
                    ] else
                      const Text(
                        'Esta unidad pertenece a un registro anterior. Actualiza la flota para administrarla por separado.',
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _VehicleInfo extends StatelessWidget {
  const _VehicleInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(label),
    subtitle: Text(value.trim().isEmpty ? 'Sin registrar' : value),
  );
}
