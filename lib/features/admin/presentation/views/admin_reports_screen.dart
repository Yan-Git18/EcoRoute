import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../viewmodels/admin_reports_state.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_assign_crew_modal.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/admin_report_card.dart';

/// Pantalla dedicada a la Bandeja Central y Asignación de Incidencias (Admin Fase 1).
///
/// Ubicación: `lib/features/admin/presentation/views/admin_reports_screen.dart`
/// Capa: Presentation (Administrador)
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final adminUser = authState.user;
    final adminName = adminUser?.name ?? 'Administrador Municipal';
    final adminId = adminUser?.id ?? 'admin-root';

    final adminState = ref.watch(adminReportsViewModelProvider);
    final viewModel = ref.read(adminReportsViewModelProvider.notifier);

    final filteredList = adminState.filteredReports;

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
              'Gestión de Reportes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${filteredList.length} incidencias en supervisión',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Actualizar reportes',
            onPressed: () => viewModel.refresh(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Buscador y Filtros superiores
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Buscador
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => viewModel.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Buscar por folio (#REP), dirección o vecino...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                viewModel.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filtros de estado con contadores
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterTab(
                        label: 'Todos',
                        count: adminState.totalCount,
                        isSelected: adminState.selectedFilter == AdminReportFilter.all,
                        onTap: () => viewModel.setFilter(AdminReportFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'Pendientes',
                        count: adminState.pendingCount,
                        isSelected: adminState.selectedFilter == AdminReportFilter.pending,
                        color: AppColors.statusPending,
                        onTap: () => viewModel.setFilter(AdminReportFilter.pending),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'Asignados',
                        count: adminState.assignedCount,
                        isSelected: adminState.selectedFilter == AdminReportFilter.assigned,
                        color: const Color(0xFF7C3AED),
                        onTap: () => viewModel.setFilter(AdminReportFilter.assigned),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'En Proceso',
                        count: adminState.inProgressCount,
                        isSelected: adminState.selectedFilter == AdminReportFilter.inProgress,
                        color: AppColors.statusInProgress,
                        onTap: () => viewModel.setFilter(AdminReportFilter.inProgress),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'Resueltos',
                        count: adminState.resolvedCount,
                        isSelected: adminState.selectedFilter == AdminReportFilter.resolved,
                        color: AppColors.statusResolved,
                        onTap: () => viewModel.setFilter(AdminReportFilter.resolved),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Listado de incidencias o pantalla vacía
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF0A5835),
              onRefresh: () => viewModel.refresh(),
              child: filteredList.isEmpty
                  ? _EmptyAdminReportsView(
                      hasQuery: _searchController.text.isNotEmpty,
                      filter: adminState.selectedFilter,
                      onReset: () {
                        _searchController.clear();
                        viewModel.setSearchQuery('');
                        viewModel.setFilter(AdminReportFilter.all);
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final report = filteredList[index];
                        return AdminReportCard(
                          report: report,
                          onAssign: () => _openAssignCrewModal(
                            report: report,
                            adminId: adminId,
                            adminName: adminName,
                          ),
                          onViewDetail: () {
                            context.push(
                              RouteNames.citizenReportDetail.replaceFirst(':id', report.id),
                              extra: report,
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 1),
    );
  }

  void _openAssignCrewModal({
    required ReportEntity report,
    required String adminId,
    required String adminName,
  }) {
    final adminState = ref.read(adminReportsViewModelProvider);
    final viewModel = ref.read(adminReportsViewModelProvider.notifier);

    AdminAssignCrewModal.show(
      context: context,
      report: report,
      crews: adminState.crews,
      onConfirm: ({required crew, required priority, instructions}) async {
        final success = await viewModel.assignReport(
          reportId: report.id,
          crew: crew,
          adminId: adminId,
          adminName: adminName,
          priority: priority,
          instructions: instructions,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${report.reportNumber} asignado exitosamente a ${crew.name} (${crew.vehicleCode}).',
              ),
              backgroundColor: const Color(0xFF047857),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return success;
      },
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A5835) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A5835) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withAlpha(50)
                    : (color?.withAlpha(30) ?? const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : (color ?? const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAdminReportsView extends StatelessWidget {
  final bool hasQuery;
  final AdminReportFilter filter;
  final VoidCallback onReset;

  const _EmptyAdminReportsView({
    required this.hasQuery,
    required this.filter,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF0A5835).withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                size: 50,
                color: Color(0xFF0A5835),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasQuery ? 'Sin incidencias encontradas' : 'No hay reportes en esta categoría',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Intenta con otro número de folio o dirección.'
                  : 'No existen incidencias en estado ${filter.label.toLowerCase()} actualmente.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Restablecer filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5835),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
