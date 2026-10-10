import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/admin_crew_card.dart';
import '../widgets/admin_crew_edit_modal.dart';

/// Pantalla de Gestión de Cuadrillas y Flota Municipal (Admin Fase 3).
///
/// Permite al Administrador supervisar el estado operativo de los camiones de recolección,
/// dotaciones de personal, reasignar zonas de cobertura y despachar unidades.
///
/// Ubicación: `lib/features/admin/presentation/views/admin_crews_screen.dart`
/// Capa: Presentation (Administrador)
class AdminCrewsScreen extends ConsumerStatefulWidget {
  const AdminCrewsScreen({super.key});

  @override
  ConsumerState<AdminCrewsScreen> createState() => _AdminCrewsScreenState();
}

class _AdminCrewsScreenState extends ConsumerState<AdminCrewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'onRoute', 'available', 'maintenance'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MunicipalCrewEntity> _filterCrews(List<MunicipalCrewEntity> crews) {
    final query = _searchController.text.trim().toLowerCase();

    return crews.where((crew) {
      // 1. Filtro por estado
      if (_selectedFilter == 'onRoute' && crew.status != MunicipalCrewStatus.onRoute) {
        return false;
      }
      if (_selectedFilter == 'available' && crew.status != MunicipalCrewStatus.available) {
        return false;
      }
      if (_selectedFilter == 'maintenance' && crew.status != MunicipalCrewStatus.maintenance) {
        return false;
      }

      // 2. Filtro por texto de búsqueda
      if (query.isNotEmpty) {
        final matchesName = crew.name.toLowerCase().contains(query);
        final matchesPlate = crew.vehiclePlate.toLowerCase().contains(query);
        final matchesCode = crew.vehicleCode.toLowerCase().contains(query);
        final matchesLeader = crew.leadStaffName.toLowerCase().contains(query);
        final matchesZone = crew.zone.toLowerCase().contains(query);
        return matchesName || matchesPlate || matchesCode || matchesLeader || matchesZone;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final adminReportsState = ref.watch(adminReportsViewModelProvider);
    final viewModel = ref.read(adminReportsViewModelProvider.notifier);

    final crews = adminReportsState.crews;
    final filteredCrews = _filterCrews(crews);

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
              'Cuadrillas y Flota Municipal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${crews.length} unidades registradas • $onRouteCount en circuito',
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
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Actualizar cuadrillas',
            onPressed: () => viewModel.refresh(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Resumen de Métricas de Flota y Buscador
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                // Fila de Métricas Rápidas
                Row(
                  children: [
                    Expanded(
                      child: _FleetStatPill(
                        label: 'Total Flota',
                        count: '${crews.length}',
                        color: const Color(0xFF0A5835),
                        icon: Icons.local_shipping_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FleetStatPill(
                        label: 'En Ruta',
                        count: '$onRouteCount',
                        color: const Color(0xFF2563EB),
                        icon: Icons.navigation_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FleetStatPill(
                        label: 'Disponibles',
                        count: '$availableCount',
                        color: const Color(0xFF059669),
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FleetStatPill(
                        label: 'Taller',
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
                    hintText: 'Buscar por cuadrilla, placa, líder o zona...',
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

                // Chips de Filtro
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _FilterChipItem(
                        label: 'Todas',
                        count: crews.length,
                        isSelected: _selectedFilter == 'all',
                        onTap: () => setState(() => _selectedFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipItem(
                        label: 'En Ruta',
                        count: onRouteCount,
                        color: const Color(0xFF2563EB),
                        isSelected: _selectedFilter == 'onRoute',
                        onTap: () => setState(() => _selectedFilter = 'onRoute'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipItem(
                        label: 'Disponibles',
                        count: availableCount,
                        color: const Color(0xFF059669),
                        isSelected: _selectedFilter == 'available',
                        onTap: () => setState(() => _selectedFilter = 'available'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipItem(
                        label: 'En Mantenimiento',
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

          // 2. Lista de Cuadrillas
          Expanded(
            child: filteredCrews.isEmpty
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
                            'No se encontraron cuadrillas',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Intenta con otro término de búsqueda o ajusta el filtro.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredCrews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final crew = filteredCrews[index];
                      return AdminCrewCard(
                        crew: crew,
                        onViewOnMap: () => context.push(RouteNames.adminLiveMap),
                        onEdit: () {
                          AdminCrewEditModal.show(
                            context: context,
                            crew: crew,
                            onConfirm: ({required status, required zone, required isAvailable}) async {
                              final messenger = ScaffoldMessenger.of(context);
                              await viewModel.updateCrew(
                                crewId: crew.id,
                                status: status,
                                zone: zone,
                                isAvailable: isAvailable,
                              );
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Unidad ${crew.vehicleCode} actualizada correctamente.'),
                                    backgroundColor: const Color(0xFF047857),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3),
    );
  }
}

class _FleetStatPill extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  final IconData icon;

  const _FleetStatPill({
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
