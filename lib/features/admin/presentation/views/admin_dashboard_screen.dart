import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/eco_notification_button.dart';
import '../../../../core/widgets/eco_section_header.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_bottom_nav_bar.dart';

/// Pantalla del panel de control para el Administrador
/// Capa: Presentation (Administrador)
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final adminReportsState = ref.watch(adminReportsViewModelProvider);

    final pendingReports = adminReportsState.reports.where((r) => r.status == ReportStatus.pending).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración Municipal'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: EcoNotificationButton(
              onTap: () => context.push(RouteNames.adminReports),
              hasUnread: adminReportsState.pendingCount > 0,
              size: 40,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ref.read(authViewModelProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminReportsViewModelProvider.notifier).refresh(),
        color: const Color(0xFF0A5835),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner de Rol
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.forest, Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.admin_panel_settings_rounded, color: AppColors.forest, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Administrador',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Gestión de Residuos Urbanos • EcoRoute',
                            style: TextStyle(color: AppColors.primaryLight, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Métricas Globales Reactivas
              const EcoSectionHeader(title: 'Resumen Municipal de Reportes'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AdminStatCard(
                      title: 'Total Reportes',
                      value: '${adminReportsState.totalCount}',
                      color: AppColors.primary,
                      icon: Icons.assignment_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdminStatCard(
                      title: 'Pendientes',
                      value: '${adminReportsState.pendingCount}',
                      color: AppColors.statusPending,
                      icon: Icons.pending_actions_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AdminStatCard(
                      title: 'En Proceso',
                      value: '${adminReportsState.inProgressCount + adminReportsState.assignedCount}',
                      color: AppColors.statusInProgress,
                      icon: Icons.sync_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdminStatCard(
                      title: 'Resueltos',
                      value: '${adminReportsState.resolvedCount}',
                      color: AppColors.statusResolved,
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Accesos de Gestión
              const EcoSectionHeader(title: 'Módulos de Gestión'),
              const SizedBox(height: 12),
              _AdminNavTile(
                title: 'Gestión y Asignación de Reportes',
                subtitle: 'Revisar, clasificar y asignar a cuadrillas',
                icon: Icons.rule_folder_rounded,
                color: AppColors.primary,
                badgeText: adminReportsState.pendingCount > 0 ? '${adminReportsState.pendingCount} por atender' : null,
                onTap: () => context.push(RouteNames.adminReports),
              ),
              const SizedBox(height: 10),
              _AdminNavTile(
                title: 'Monitoreo en Mapa en Tiempo Real',
                subtitle: 'Ver incidencias por zona geográfica y cuadrillas (Fase 2)',
                icon: Icons.map_rounded,
                color: AppColors.info,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Monitoreo en Mapa Urbano se habilitará en la Fase 2.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _AdminNavTile(
                title: 'Gestión de Cuadrillas y Flota',
                subtitle: 'Disponibilidad de operarios y camiones (Fase 3)',
                icon: Icons.local_shipping_rounded,
                color: AppColors.warning,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gestión de Cuadrillas y Flota se habilitará en la Fase 3.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              // Sección rápida de incidencias pendientes
              if (pendingReports.isNotEmpty) ...[
                const SizedBox(height: 24),
                EcoSectionHeader(
                  title: 'Incidencias Pendientes Urgentes',
                  actionText: 'Ver todas (${pendingReports.length})',
                  onActionTap: () => context.push(RouteNames.adminReports),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notification_important_rounded, color: Color(0xFFD97706), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pendingReports.first.categoryName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pendingReports.first.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => context.push(RouteNames.adminReports),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A5835),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Atender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 0),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badgeText;
  final VoidCallback onTap;

  const _AdminNavTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
      ),
    );
  }
}
