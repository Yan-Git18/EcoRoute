import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/eco_notification_button.dart';
import '../../../../core/widgets/eco_section_header.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

/// Pantalla del panel de control para el Administrador
/// Capa: Presentation (Administrador)
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración Municipal'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: EcoNotificationButton(
              onTap: () {},
              hasUnread: false,
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
      body: SingleChildScrollView(
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

            // Métricas Globales
            const EcoSectionHeader(title: 'Resumen Municipal de Reportes'),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: _AdminStatCard(
                    title: 'Total Reportes',
                    value: '142',
                    color: AppColors.primary,
                    icon: Icons.assignment_rounded,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _AdminStatCard(
                    title: 'Pendientes',
                    value: '38',
                    color: AppColors.statusPending,
                    icon: Icons.pending_actions_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: _AdminStatCard(
                    title: 'En Proceso',
                    value: '19',
                    color: AppColors.statusInProgress,
                    icon: Icons.sync_rounded,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _AdminStatCard(
                    title: 'Resueltos',
                    value: '85',
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
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _AdminNavTile(
              title: 'Monitoreo en Mapa en Tiempo Real',
              subtitle: 'Ver incidencias por zona geográfica y cuadrillas',
              icon: Icons.map_rounded,
              color: AppColors.info,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _AdminNavTile(
              title: 'Planificador de Rutas de Limpieza',
              subtitle: 'Optimización de trayectos con Google Routes',
              icon: Icons.alt_route_rounded,
              color: AppColors.warning,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _AdminNavTile(
              title: 'Catálogo de Categorías y SLAs',
              subtitle: 'Administrar tipos de residuos y tiempos de respuesta',
              icon: Icons.category_rounded,
              color: AppColors.forest,
              onTap: () {},
            ),
          ],
        ),
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
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
  final VoidCallback onTap;

  const _AdminNavTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
      ),
    );
  }
}
