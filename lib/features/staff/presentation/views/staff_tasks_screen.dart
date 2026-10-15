import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/report_filter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/staff_task_entity.dart';
import '../viewmodels/staff_home_viewmodel.dart';
import '../widgets/staff_bottom_nav_bar.dart';
import '../widgets/staff_complete_task_sheet.dart';
import '../widgets/staff_task_item_card.dart';

/// Enum para opciones de ordenamiento de tareas en StaffTasksScreen
enum StaffTaskSortOrder {
  priority('Prioridad (Alta primero)'),
  recent('Más recientes');

  final String label;
  const StaffTaskSortOrder(this.label);
}

/// Pantalla dedicada a la Gestión Completa de Tareas del Personal (Fase 1).
///
/// Permite buscar por dirección o folio, filtrar por estado con contadores en tiempo real,
/// ordenar por prioridad o fecha, e interactuar directamente (iniciar atención y completar con evidencia).
///
/// Ubicación: `lib/features/staff/presentation/views/staff_tasks_screen.dart`
/// Capa: Presentation (Personal)
class StaffTasksScreen extends ConsumerStatefulWidget {
  const StaffTasksScreen({super.key});

  @override
  ConsumerState<StaffTasksScreen> createState() => _StaffTasksScreenState();
}

class _StaffTasksScreenState extends ConsumerState<StaffTasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  StaffTaskSortOrder _sortOrder = StaffTaskSortOrder.priority;

  // Tareas de demostración para visualización inicial si la base de datos está vacía
  static final List<StaffTaskEntity> _defaultDemoTasks = [
    StaffTaskEntity(
      id: 'task-demo-1',
      reportNumber: '#0102',
      citizenId: 'c-demo-1',
      citizenName: 'Vecino Ciudadano',
      categoryName: 'Contenedor lleno',
      categoryIcon: 'delete_outline_rounded',
      description: 'Contenedor saturado en la avenida principal.',
      priority: ReportPriority.high,
      status: ReportStatus.pending,
      address: 'Av. Los Próceres 452',
      latitude: -12.046,
      longitude: -77.042,
      reportImageUrls: const [],
      assignedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    StaffTaskEntity(
      id: 'task-demo-2',
      reportNumber: '#0103',
      citizenId: 'c-demo-2',
      citizenName: 'Vecino Ciudadano',
      categoryName: 'Residuos en vía pública',
      categoryIcon: 'cleaning_services_rounded',
      description: 'Restos de poda y bolsas en vereda.',
      priority: ReportPriority.medium,
      status: ReportStatus.pending,
      address: 'Jr. Amazonas 120',
      latitude: -12.047,
      longitude: -77.043,
      reportImageUrls: const [],
      assignedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    StaffTaskEntity(
      id: 'task-demo-3',
      reportNumber: '#0104',
      citizenId: 'c-demo-3',
      citizenName: 'Vecino Ciudadano',
      categoryName: 'Punto de recolección',
      categoryIcon: 'recycling_rounded',
      description: 'Limpieza periódica de contenedores verdes.',
      priority: ReportPriority.low,
      status: ReportStatus.pending,
      address: 'Parque Central',
      latitude: -12.048,
      longitude: -77.044,
      reportImageUrls: const [],
      assignedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    StaffTaskEntity(
      id: 'task-demo-4',
      reportNumber: '#0105',
      citizenId: 'c-demo-4',
      citizenName: 'Vecino Ciudadano',
      categoryName: 'Acumulación de maleza',
      categoryIcon: 'delete_sweep_rounded',
      description: 'Restos vegetales en vereda.',
      priority: ReportPriority.medium,
      status: ReportStatus.pending,
      address: 'Av. Las Palmas 890',
      latitude: -12.049,
      longitude: -77.045,
      reportImageUrls: const [],
      assignedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    StaffTaskEntity(
      id: 'task-demo-5',
      reportNumber: '#0101',
      citizenId: 'c-demo-5',
      citizenName: 'Vecino Ciudadano',
      categoryName: 'Desborde de basura',
      categoryIcon: 'delete_outline_rounded',
      description: 'Cuadrilla atendiendo en zona con camión recolector.',
      priority: ReportPriority.high,
      status: ReportStatus.inProgress,
      address: 'Calle Los Pinos 88',
      latitude: -12.050,
      longitude: -77.046,
      reportImageUrls: const [],
      assignedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    StaffTaskEntity(
      id: 'task-demo-6',
      reportNumber: '#0099',
      citizenId: 'c-demo-6',
      citizenName: 'Vecino Ciudadano',
      categoryName: 'Limpieza de zona',
      categoryIcon: 'check_circle_outline_rounded',
      description: 'Limpieza de esquina completada y sanitizada.',
      priority: ReportPriority.low,
      status: ReportStatus.resolved,
      address: 'Sector 1 - Jr. Callao 340',
      latitude: -12.045,
      longitude: -77.041,
      reportImageUrls: const [],
      assignedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffHomeViewModelProvider);
    final viewModel = ref.read(staffHomeViewModelProvider.notifier);

    final allTasks = staffState.tasks.isNotEmpty ? staffState.tasks : _defaultDemoTasks;

    final pendingCount = allTasks.where((t) => t.isPending).length;
    final inProgressCount = allTasks.where((t) => t.isInProgress).length;
    final resolvedCount = allTasks.where((t) => t.isResolved).length;

    // 1. Filtrado por estado
    var filteredList = switch (staffState.selectedFilter) {
      ReportFilter.pending => allTasks.where((t) => t.isPending).toList(),
      ReportFilter.inProgress => allTasks.where((t) => t.isInProgress).toList(),
      ReportFilter.resolved => allTasks.where((t) => t.isResolved).toList(),
      ReportFilter.all => allTasks,
    };

    // 2. Filtrado por búsqueda de texto
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filteredList = filteredList.where((t) {
        return t.reportNumber.toLowerCase().contains(query) ||
            t.categoryName.toLowerCase().contains(query) ||
            t.address.toLowerCase().contains(query) ||
            t.description.toLowerCase().contains(query);
      }).toList();
    }

    // 3. Ordenamiento
    final sortedList = List<StaffTaskEntity>.from(filteredList);
    if (_sortOrder == StaffTaskSortOrder.priority) {
      sortedList.sort((a, b) {
        // Orden: high -> medium -> low
        final priorityRank = {
          ReportPriority.high: 0,
          ReportPriority.medium: 1,
          ReportPriority.low: 2,
        };
        return (priorityRank[a.priority] ?? 1).compareTo(priorityRank[b.priority] ?? 1);
      });
    } else {
      sortedList.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
    }

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
              context.go(RouteNames.staffHome);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de Tareas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${sortedList.length} incidencias asignadas a tu personal',
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
            tooltip: 'Actualizar tareas',
            onPressed: () => viewModel.refresh(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Franja de Filtros y Búsqueda superior fija
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Buscador de Tareas
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar por folio (#0102), dirección o residuo...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Chips de filtro por estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Todas',
                        count: allTasks.length,
                        isSelected: staffState.selectedFilter == ReportFilter.all,
                        onTap: () => viewModel.setFilter(ReportFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pendientes',
                        count: pendingCount,
                        isSelected: staffState.selectedFilter == ReportFilter.pending,
                        badgeColor: AppColors.statusPending,
                        onTap: () => viewModel.setFilter(ReportFilter.pending),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'En proceso',
                        count: inProgressCount,
                        isSelected: staffState.selectedFilter == ReportFilter.inProgress,
                        badgeColor: AppColors.statusInProgress,
                        onTap: () => viewModel.setFilter(ReportFilter.inProgress),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Resueltas',
                        count: resolvedCount,
                        isSelected: staffState.selectedFilter == ReportFilter.resolved,
                        badgeColor: AppColors.statusResolved,
                        onTap: () => viewModel.setFilter(ReportFilter.resolved),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Barra de información de ordenamiento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Ordenar por: ${_sortOrder.label}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<StaffTaskSortOrder>(
                  tooltip: 'Cambiar orden',
                  icon: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF0A5835)),
                  padding: EdgeInsets.zero,
                  onSelected: (order) => setState(() => _sortOrder = order),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: StaffTaskSortOrder.priority,
                      child: Text('Prioridad (Alta primero)'),
                    ),
                    const PopupMenuItem(
                      value: StaffTaskSortOrder.recent,
                      child: Text('Más recientes'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Listado de tareas o estado vacío
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF0A5835),
              onRefresh: () => viewModel.refresh(),
              child: sortedList.isEmpty
                  ? _EmptyTasksListView(
                      hasQuery: _searchController.text.isNotEmpty,
                      filter: staffState.selectedFilter,
                      onClear: () {
                        _searchController.clear();
                        viewModel.setFilter(ReportFilter.all);
                        setState(() {});
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: sortedList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = sortedList[index];
                        return StaffTaskItemCard(
                          task: task,
                          isNextTask: index == 0 && task.isPending && staffState.selectedFilter == ReportFilter.all,
                          onStart: () => _handleStartTask(task),
                          onResolve: () => StaffCompleteTaskSheet.show(context, task),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: 2,
        onTabSelected: (index) {
          if (index == 0) {
            context.go(RouteNames.staffHome);
          } else if (index == 1) {
            context.push(RouteNames.staffRouteMap);
          } else if (index == 2) {
            // Ya en tareas
          } else if (index == 3) {
            context.push(RouteNames.staffProfile);
          }
        },
      ),
    );
  }

  Future<void> _handleStartTask(StaffTaskEntity task) async {
    final viewModel = ref.read(staffHomeViewModelProvider.notifier);
    final success = await viewModel.startTask(task.id);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Atención iniciada para ${task.reportNumber}. Estado en proceso.'),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A5835) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
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
                    : (badgeColor?.withAlpha(30) ?? const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? Colors.white
                      : (badgeColor ?? const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTasksListView extends StatelessWidget {
  final bool hasQuery;
  final ReportFilter filter;
  final VoidCallback onClear;

  const _EmptyTasksListView({
    required this.hasQuery,
    required this.filter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
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
                size: 52,
                color: Color(0xFF0A5835),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasQuery ? 'Sin resultados para la búsqueda' : 'No hay tareas en este estado',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Intenta con otros términos como dirección o folio.'
                  : 'Tu personal no tiene incidencias ${filter.label.toLowerCase()} en este momento.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Restablecer filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5835),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
