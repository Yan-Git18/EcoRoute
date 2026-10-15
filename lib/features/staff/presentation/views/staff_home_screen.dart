import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/geo_constants.dart';
import '../../../../core/enums/report_filter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/eco_logo_badge.dart';
import '../../../../core/widgets/eco_notification_button.dart';
import '../../../../core/widgets/eco_section_header.dart';
import '../../../../core/widgets/eco_status_summary_card.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/staff_task_entity.dart';
import '../viewmodels/staff_home_viewmodel.dart';
import '../widgets/staff_bottom_nav_bar.dart';
import '../widgets/staff_complete_task_sheet.dart';
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

  // Tareas de demostración para Cajamarca, Perú si la base de datos está vacía
  static final List<StaffTaskEntity> _defaultDemoTasks = [
    StaffTaskEntity(
      id: 'task-demo-1',
      reportNumber: '#0102',
      citizenId: 'c-demo-1',
      citizenName: 'Vecino Ciudadano',
      categoryName: 'Contenedor lleno',
      categoryIcon: 'delete_outline_rounded',
      description: 'Contenedor saturado en Jr. Del Comercio.',
      priority: ReportPriority.high,
      status: ReportStatus.pending,
      address: 'Av. Los Próceres 452',
      latitude: -7.1580,
      longitude: -78.5180,
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
      latitude: -7.1565,
      longitude: -78.5160,
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
      latitude: -7.1578,
      longitude: -78.5175,
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
      latitude: -7.1610,
      longitude: -78.5210,
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
      latitude: -7.1520,
      longitude: -78.5130,
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
        latitude: -7.1600 - (i * 0.001),
        longitude: -78.5150 - (i * 0.001),
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

    final urgentTask = allTasks.where((t) => t.isPending && t.priority == ReportPriority.high).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: const [
            EcoLogoBadge(size: 38, iconSize: 22),
            SizedBox(width: 12),
            Text(
              'Panel de Operaciones',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
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
              // 1. Cabecera limpia y moderna del personal (reemplaza la tarjeta verde abultada)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staffName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: const [
                            Icon(Icons.shield_outlined, size: 14, color: Color(0xFF047857)),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Cuadrilla Zona Norte',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Pill de control de estado de turno (discreto y elegante)
                  InkWell(
                    onTap: () => StaffShiftStatusModal.show(
                      context: context,
                      currentStatus: _shiftStatus,
                      onStatusSelected: (status) => setState(() => _shiftStatus = status),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getShiftStatusColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _shiftStatus,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _getShiftStatusColor(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Cambiar estado',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Información importante para el personal: Hero Card de Circuito Operativo en Cajamarca
              _buildOperationalCircuitCard(
                context: context,
                pendingCount: pendingCount,
                resolvedCount: resolvedCount,
                totalCount: allTasks.length,
              ),
              const SizedBox(height: 18),

              // 3. Alerta de incidencia prioritaria (si existe reporte de alta prioridad pendiente)
              if (urgentTask != null) ...[
                _buildUrgentTaskAlert(
                  task: urgentTask,
                  onTap: () => StaffCompleteTaskSheet.show(context, urgentTask),
                ),
                const SizedBox(height: 18),
              ],

              // 4. Acciones Operativas Rápidas
              Row(
                children: [
                  Expanded(
                    child: _OperationalActionCard(
                      icon: Icons.map_rounded,
                      iconColor: const Color(0xFF047857),
                      iconBgColor: const Color(0xFFDCFCE7),
                      title: 'Mapa de Ruta',
                      subtitle: 'Circuito en Cajamarca',
                      onTap: () => context.push(RouteNames.staffRouteMap),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OperationalActionCard(
                      icon: Icons.assignment_outlined,
                      iconColor: const Color(0xFF2563EB),
                      iconBgColor: const Color(0xFFEFF6FF),
                      title: 'Todas las Tareas',
                      subtitle: 'Gestión y filtros',
                      onTap: () => context.push(RouteNames.staffTasks),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Sección "Mis tareas" con contadores de métricas
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

              // 6. Sección "Siguiente tarea"
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

              // 7. Sección "Otras tareas"
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
            context.push(RouteNames.staffProfile);
          }
        },
      ),
    );
  }

  /// Tarjeta de Información Operativa Destacada (Circuito de Ruta y Camión)
  Widget _buildOperationalCircuitCard({
    required BuildContext context,
    required int pendingCount,
    required int resolvedCount,
    required int totalCount,
  }) {
    final double progress = totalCount > 0 ? (resolvedCount / totalCount).clamp(0.0, 1.0) : 0.0;
    final int percentage = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28047857),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Circuito Cajamarca Centro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Camión #04 • Sector Urbano',
                        style: TextStyle(
                          color: Color(0xFFD1FAE5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pendingCount pendientes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barra de progreso de recolección del día
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progreso de paradas hoy',
                    style: TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$percentage% ($resolvedCount/$totalCount atendidas)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: Colors.white.withAlpha(45),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Botón directo para abrir el mapa de ruta en Cajamarca
          InkWell(
            onTap: () => context.push(RouteNames.staffRouteMap),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.map_rounded, size: 16, color: Color(0xFF047857)),
                  SizedBox(width: 8),
                  Text(
                    'Ver mapa de ruta en Cajamarca',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF047857)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Banner de alerta para incidencias prioritarias
  Widget _buildUrgentTaskAlert({
    required StaffTaskEntity task,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'URGENTE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.reportNumber,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.categoryName} • ${task.address}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Ver alerta',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
                          'Tienes $pending tareas pendientes y $inProgress en proceso asignadas a tu personal.',
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
}

/// Tarjeta compacta para acciones rápidas operativas del personal
class _OperationalActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OperationalActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
