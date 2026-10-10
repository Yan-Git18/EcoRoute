import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/report_filter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/eco_notification_button.dart';
import '../../../../core/widgets/eco_section_header.dart';
import '../../../../core/widgets/eco_status_summary_card.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/staff_task_entity.dart';
import '../viewmodels/staff_home_viewmodel.dart';
import '../widgets/staff_bottom_nav_bar.dart';
import '../widgets/staff_complete_task_sheet.dart';
import '../widgets/staff_drawer.dart';
import '../widgets/staff_shift_status_card.dart';
import '../widgets/staff_shift_status_modal.dart';
import '../widgets/staff_task_item_card.dart';

/// Pantalla principal para el Personal de Limpieza / Recolección (Staff).
/// Capa: Presentation (Personal)
class StaffHomeScreen extends ConsumerStatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  ConsumerState<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends ConsumerState<StaffHomeScreen> {
  String _shiftStatus = 'En turno';
  final int _currentNavIndex = 0; // 'Inicio' activo en la pantalla principal

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
      assignedAt: DateTime.now(),
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
      assignedAt: DateTime.now(),
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
      assignedAt: DateTime.now(),
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
      assignedAt: DateTime.now(),
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
      assignedAt: DateTime.now(),
    ),
    ...List.generate(
      6,
      (i) => StaffTaskEntity(
        id: 'task-res-$i',
        reportNumber: '#009${i + 1}',
        citizenId: 'c-res',
        citizenName: 'Vecino Ciudadano',
        categoryName: 'Limpieza de zona',
        categoryIcon: 'check_circle_outline_rounded',
        description: 'Limpieza completada y validada.',
        priority: ReportPriority.low,
        status: ReportStatus.resolved,
        address: 'Sector ${i + 1}',
        latitude: -12.045,
        longitude: -77.041,
        reportImageUrls: const [],
        assignedAt: DateTime.now().subtract(Duration(days: i + 1)),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final staffName = user?.name ?? 'Mario Limpieza';

    final staffState = ref.watch(staffHomeViewModelProvider);
    final viewModel = ref.read(staffHomeViewModelProvider.notifier);

    final allTasks = staffState.tasks.isNotEmpty ? staffState.tasks : _defaultDemoTasks;

    final pendingCount = allTasks.where((t) => t.isPending).length;
    final inProgressCount = allTasks.where((t) => t.isInProgress).length;
    final resolvedCount = allTasks.where((t) => t.isResolved).length;

    final filteredTasks = switch (staffState.selectedFilter) {
      ReportFilter.pending => allTasks.where((t) => t.isPending).toList(),
      ReportFilter.inProgress => allTasks.where((t) => t.isInProgress).toList(),
      ReportFilter.resolved => allTasks.where((t) => t.isResolved).toList(),
      ReportFilter.all => allTasks,
    };

    StaffTaskEntity? nextTask;
    List<StaffTaskEntity> otherTasks = [];

    if (staffState.selectedFilter == ReportFilter.all) {
      final highPriorityPending =
          allTasks.where((t) => t.isPending && t.priority == ReportPriority.high).toList();
      final inProgressTasks = allTasks.where((t) => t.isInProgress).toList();
      final normalPending = allTasks.where((t) => t.isPending).toList();

      if (highPriorityPending.isNotEmpty) {
        nextTask = highPriorityPending.first;
      } else if (inProgressTasks.isNotEmpty) {
        nextTask = inProgressTasks.first;
      } else if (normalPending.isNotEmpty) {
        nextTask = normalPending.first;
      } else if (allTasks.isNotEmpty) {
        nextTask = allTasks.first;
      }

      otherTasks = allTasks.where((t) => t.id != nextTask?.id && !t.isResolved).toList();
    } else {
      if (filteredTasks.isNotEmpty) {
        nextTask = filteredTasks.first;
        otherTasks = filteredTasks.skip(1).toList();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: StaffDrawer(staffName: staffName, email: user?.email),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text(
          'Panel de Operaciones',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: EcoNotificationButton(
              onTap: () => _showNotificationsModal(context, pendingCount, inProgressCount),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.refresh(),
        color: const Color(0xFF0A5835),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Tarjeta superior del Operario / Cuadrilla
              StaffShiftStatusCard(
                staffName: staffName,
                shiftStatus: _shiftStatus,
                statusColor: _getShiftStatusColor(),
                onTapChangeStatus: () => StaffShiftStatusModal.show(
                  context: context,
                  currentStatus: _shiftStatus,
                  onStatusSelected: (status) => setState(() => _shiftStatus = status),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Sección "Mis tareas" con contadores de métricas
              EcoSectionHeader(
                title: 'Mis tareas',
                actionText: 'Ver todas',
                onActionTap: () => context.push(RouteNames.staffTasks),
              ),
              const SizedBox(height: 12),
              EcoStatusSummaryCard(
                items: [
                  EcoStatusItem(
                    count: '$pendingCount',
                    label: 'Pendientes',
                    color: const Color(0xFFF59E0B),
                    isSelected: staffState.selectedFilter == ReportFilter.pending,
                    onTap: () => viewModel.setFilter(
                      staffState.selectedFilter == ReportFilter.pending
                          ? ReportFilter.all
                          : ReportFilter.pending,
                    ),
                  ),
                  EcoStatusItem(
                    count: '$inProgressCount',
                    label: 'En proceso',
                    color: const Color(0xFF3B82F6),
                    isSelected: staffState.selectedFilter == ReportFilter.inProgress,
                    onTap: () => viewModel.setFilter(
                      staffState.selectedFilter == ReportFilter.inProgress
                          ? ReportFilter.all
                          : ReportFilter.inProgress,
                    ),
                  ),
                  EcoStatusItem(
                    count: '$resolvedCount',
                    label: 'Resueltas',
                    color: const Color(0xFF059669),
                    isSelected: staffState.selectedFilter == ReportFilter.resolved,
                    onTap: () => viewModel.setFilter(
                      staffState.selectedFilter == ReportFilter.resolved
                          ? ReportFilter.all
                          : ReportFilter.resolved,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Sección "Siguiente tarea"
              if (nextTask != null) ...[
                const EcoSectionHeader(title: 'Siguiente tarea'),
                const SizedBox(height: 12),
                StaffTaskItemCard(
                  task: nextTask,
                  isNextTask: true,
                  onStart: () => _handleStartTask(nextTask!),
                  onResolve: () => StaffCompleteTaskSheet.show(context, nextTask!),
                ),
                const SizedBox(height: 24),
              ],

              // 4. Sección "Otras tareas"
              EcoSectionHeader(
                title: 'Otras tareas',
                actionText: 'Ver todas',
                onActionTap: () => viewModel.setFilter(ReportFilter.all),
              ),
              const SizedBox(height: 12),
              if (otherTasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      'No hay más tareas pendientes en esta categoría.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: otherTasks.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, index) {
                      final task = otherTasks[index];
                      return StaffTaskItemCard(
                        task: task,
                        isNextTask: false,
                        onStart: () => _handleStartTask(task),
                        onResolve: () => StaffCompleteTaskSheet.show(context, task),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: _currentNavIndex,
        onTabSelected: (index) {
          if (index == 0) {
            viewModel.setFilter(ReportFilter.all);
          } else if (index == 1) {
            context.push(RouteNames.staffRouteMap);
          } else if (index == 2) {
            context.push(RouteNames.staffTasks);
          } else if (index == 3) {
            _showProfileModal(context, ref, staffName, user?.email);
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
        const SnackBar(
          content: Text('Atención iniciada. Estado actualizado a "En proceso".'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  Color _getShiftStatusColor() {
    switch (_shiftStatus) {
      case 'En turno':
        return const Color(0xFF10B981);
      case 'En descanso':
        return const Color(0xFFF59E0B);
      case 'Fin de turno':
      default:
        return const Color(0xFF94A3B8);
    }
  }

  void _showNotificationsModal(BuildContext context, int pending, int inProgress) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notificaciones operativas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_rounded,
                          color: Color(0xFF047857),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tienes $pending tareas pendientes y $inProgress en proceso asignadas a tu cuadrilla.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileModal(BuildContext context, WidgetRef ref, String name, String? email) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.person_rounded, size: 36, color: Color(0xFF047857)),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (email != null) Text(email, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(authViewModelProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                    label: const Text('Cerrar Sesión', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
