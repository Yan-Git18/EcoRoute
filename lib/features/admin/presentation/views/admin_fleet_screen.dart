import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_bottom_nav_bar.dart';

/// Pantalla especializada para la Gestión de Flota y Maquinaria Municipal.
///
/// Principio SRP: Responsable exclusiva del parque automotor (camiones, compactadores,
/// placas, estado mecánico y mantenimiento en taller).
///
/// Ubicación: `lib/features/admin/presentation/views/admin_fleet_screen.dart`
/// Capa: Presentation (Administrador)
class AdminFleetScreen extends ConsumerStatefulWidget {
  const AdminFleetScreen({super.key});

  @override
  ConsumerState<AdminFleetScreen> createState() => _AdminFleetScreenState();
}

class _AdminFleetScreenState extends ConsumerState<AdminFleetScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'onRoute', 'available', 'maintenance'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MunicipalCrewEntity> _filterVehicles(List<MunicipalCrewEntity> crews) {
    final query = _searchController.text.trim().toLowerCase();

    return crews.where((crew) {
      // 1. Filtro por estado mecánico
      if (_selectedFilter == 'onRoute' && crew.status != MunicipalCrewStatus.onRoute) {
        return false;
      }
      if (_selectedFilter == 'available' && crew.status != MunicipalCrewStatus.available) {
        return false;
      }
      if (_selectedFilter == 'maintenance' && crew.status != MunicipalCrewStatus.maintenance) {
        return false;
      }

      // 2. Filtro por búsqueda (código, placa, tipo, cuadrilla o conductor)
      if (query.isNotEmpty) {
        final matchesCode = crew.vehicleCode.toLowerCase().contains(query);
        final matchesPlate = crew.vehiclePlate.toLowerCase().contains(query);
        final matchesType = crew.vehicleType.toLowerCase().contains(query);
        final matchesCrew = crew.name.toLowerCase().contains(query);
        final matchesDriver = crew.leadStaffName.toLowerCase().contains(query);
        return matchesCode || matchesPlate || matchesType || matchesCrew || matchesDriver;
      }

      return true;
    }).toList();
  }

  void _showVehicleEditDialog(BuildContext context, MunicipalCrewEntity crew, AdminReportsViewModel viewModel) {
    final codeCtrl = TextEditingController(text: crew.vehicleCode);
    final plateCtrl = TextEditingController(text: crew.vehiclePlate);
    String selectedType = crew.vehicleType;

    const vehicleTypes = [
      'Camión Compactador 15m³',
      'Furgón Barrendero Ligero',
      'Camión Recolector Urbano',
      'Camión Volquete Pesado',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A5835).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.build_rounded, color: Color(0xFF0A5835), size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Editar Vehículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Código de Unidad', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: codeCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ej. Camión #04',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Placa Vehicular', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: plateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Ej. ECR-882',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Tipo de Vehículo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12.5)))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final messenger = ScaffoldMessenger.of(context);
                final success = await viewModel.updateCrew(
                  crewId: crew.id,
                  vehicleCode: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : crew.vehicleCode,
                  vehiclePlate: plateCtrl.text.trim().isNotEmpty ? plateCtrl.text.trim().toUpperCase() : crew.vehiclePlate,
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Vehículo ${codeCtrl.text} actualizado en Firestore.' : 'Error al actualizar vehículo.'),
                      backgroundColor: success ? const Color(0xFF047857) : const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5835),
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewVehicleDialog(BuildContext context, AdminReportsViewModel viewModel) {
    final codeCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    final crewNameCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final zoneCtrl = TextEditingController();
    String selectedType = 'Camión Compactador 15m³';

    const vehicleTypes = [
      'Camión Compactador 15m³',
      'Furgón Barrendero Ligero',
      'Camión Recolector Urbano',
      'Camión Volquete Pesado',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A5835).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF0A5835), size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Alta de Vehículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Código de Unidad', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: codeCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ej. Camión #06',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Placa Vehicular', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: plateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Ej. ECR-912',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Tipo de Vehículo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12.5)))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Cuadrilla Asignada', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: crewNameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ej. Cuadrilla Zona Este',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Conductor / Líder', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: driverCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ej. Juan Choque',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Sector Habitual', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: zoneCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ej. Sector 5 (Av. Javier Prado)',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (codeCtrl.text.trim().isEmpty || plateCtrl.text.trim().isEmpty) return;

                Navigator.pop(dialogCtx);
                final messenger = ScaffoldMessenger.of(context);

                final newEntity = MunicipalCrewEntity(
                  id: '',
                  name: crewNameCtrl.text.trim().isNotEmpty ? crewNameCtrl.text.trim() : 'Cuadrilla ${codeCtrl.text.trim()}',
                  zone: zoneCtrl.text.trim().isNotEmpty ? zoneCtrl.text.trim() : 'Sector General',
                  leadStaffName: driverCtrl.text.trim().isNotEmpty ? driverCtrl.text.trim() : 'Conductor Asignado',
                  vehicleCode: codeCtrl.text.trim(),
                  vehiclePlate: plateCtrl.text.trim().toUpperCase(),
                  vehicleType: selectedType,
                  status: MunicipalCrewStatus.available,
                );

                final success = await viewModel.createCrew(newEntity);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Vehículo ${codeCtrl.text} registrado en la flota.' : 'Error al registrar vehículo.'),
                      backgroundColor: success ? const Color(0xFF047857) : const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5835),
                foregroundColor: Colors.white,
              ),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminReportsState = ref.watch(adminReportsViewModelProvider);
    final viewModel = ref.read(adminReportsViewModelProvider.notifier);

    final crews = adminReportsState.crews;
    final filteredVehicles = _filterVehicles(crews);

    final onRouteCount = crews.where((c) => c.status == MunicipalCrewStatus.onRoute).length;
    final availableCount = crews.where((c) => c.status == MunicipalCrewStatus.available).length;
    final maintenanceCount = crews.where((c) => c.status == MunicipalCrewStatus.maintenance).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.adminDashboard);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flota y Maquinaria Municipal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${crews.length} unidades • $maintenanceCount en mantenimiento',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF047857),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined, color: Color(0xFF0A5835)),
            tooltip: 'Ver Cuadrillas',
            onPressed: () => context.push(RouteNames.adminTeams),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Actualizar flota',
            onPressed: () => viewModel.refresh(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Resumen de Métricas Vehiculares y Buscador
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _VehicleStatPill(
                        label: 'Total Flota',
                        count: '${crews.length}',
                        color: const Color(0xFF0A5835),
                        icon: Icons.local_shipping_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _VehicleStatPill(
                        label: 'En Circuito',
                        count: '$onRouteCount',
                        color: const Color(0xFF2563EB),
                        icon: Icons.navigation_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _VehicleStatPill(
                        label: 'En Base',
                        count: '$availableCount',
                        color: const Color(0xFF059669),
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _VehicleStatPill(
                        label: 'En Taller',
                        count: '$maintenanceCount',
                        color: const Color(0xFFDC2626),
                        icon: Icons.build_circle_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Buscador
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar por placa, código de unidad o conductor...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Chips de filtro
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _FilterChipItem(
                        label: 'Todos',
                        count: crews.length,
                        isSelected: _selectedFilter == 'all',
                        onTap: () => setState(() => _selectedFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipItem(
                        label: 'En Circuito',
                        count: onRouteCount,
                        color: const Color(0xFF2563EB),
                        isSelected: _selectedFilter == 'onRoute',
                        onTap: () => setState(() => _selectedFilter = 'onRoute'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipItem(
                        label: 'En Base',
                        count: availableCount,
                        color: const Color(0xFF059669),
                        isSelected: _selectedFilter == 'available',
                        onTap: () => setState(() => _selectedFilter = 'available'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipItem(
                        label: 'En Taller',
                        count: maintenanceCount,
                        color: const Color(0xFFDC2626),
                        isSelected: _selectedFilter == 'maintenance',
                        onTap: () => setState(() => _selectedFilter = 'maintenance'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 2. Listado de Unidades Vehiculares
          Expanded(
            child: filteredVehicles.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A5835).withAlpha(15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_shipping_outlined, size: 48, color: Color(0xFF0A5835)),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No se encontraron vehículos',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Prueba con otra placa o código de camión.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredVehicles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final vehicle = filteredVehicles[index];
                      final isInMaintenance = vehicle.status == MunicipalCrewStatus.maintenance;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isInMaintenance ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                            width: isInMaintenance ? 1.5 : 1,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fila Superior: Código, Placa y Estado
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isInMaintenance ? const Color(0xFFDC2626) : const Color(0xFF0A5835)).withAlpha(20),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.local_shipping_rounded,
                                    color: isInMaintenance ? const Color(0xFFDC2626) : const Color(0xFF0A5835),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehicle.vehicleCode,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        vehicle.vehicleType,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                // Badge Placa Estilo Matrícula
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFF59E0B)),
                                  ),
                                  child: Text(
                                    vehicle.vehiclePlate,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                      color: Color(0xFF92400E),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Fila Asignación
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_pin_rounded, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Conductor: ${vehicle.leadStaffName} • ${vehicle.name}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Botones de Acción Mecánica
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showVehicleEditDialog(context, vehicle, viewModel),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Modificar', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF334155),
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final newStatus = isInMaintenance
                                          ? MunicipalCrewStatus.available
                                          : MunicipalCrewStatus.maintenance;
                                      final success = await viewModel.updateCrew(
                                        crewId: vehicle.id,
                                        status: newStatus,
                                        isAvailable: !isInMaintenance,
                                      );
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              success
                                                  ? (isInMaintenance
                                                      ? 'Unidad ${vehicle.vehicleCode} dada de alta y disponible.'
                                                      : 'Unidad ${vehicle.vehicleCode} enviada a Taller Mecánico.')
                                                  : 'Error al cambiar estado mecánico.',
                                            ),
                                            backgroundColor: success
                                                ? (isInMaintenance ? const Color(0xFF047857) : const Color(0xFFDC2626))
                                                : const Color(0xFFDC2626),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      isInMaintenance ? Icons.check_circle_outline_rounded : Icons.build_circle_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      isInMaintenance ? 'Retorno de Taller' : 'Enviar a Taller',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isInMaintenance ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewVehicleDialog(context, viewModel),
        backgroundColor: const Color(0xFF0A5835),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Camión', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3),
    );
  }
}

class _VehicleStatPill extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  final IconData icon;

  const _VehicleStatPill({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            count,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, height: 1.1),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFF0A5835);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? activeColor : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(50) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

