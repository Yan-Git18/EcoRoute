import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

/// Pantalla principal (Dashboard) para el rol Ciudadano.
/// 
/// Ubicación: `lib/features/citizen/presentation/views/citizen_home_screen.dart`
/// Capa: Presentation (Ciudadano)
class CitizenHomeScreen extends ConsumerWidget {
  const CitizenHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('EcoRoute'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo personalizado y lema
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.forest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, ${user?.name.split(' ').first ?? 'Ciudadano'}!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Juntos por ciudades más limpias. Tu reporte ayuda a mejorar el entorno urbano.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primarySoft,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push(RouteNames.citizenCreateReport),
                    icon: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary),
                    label: const Text(
                      'Reportar Problema',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.forest,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Acciones Rápidas
            Text(
              'Servicios Ciudadanos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.15,
              children: [
                _ActionCard(
                  title: 'Crear Reporte',
                  subtitle: 'Flujo en 4 pasos',
                  icon: Icons.add_circle_outline,
                  color: AppColors.primary,
                  onTap: () => context.push(RouteNames.citizenCreateReport),
                ),
                _ActionCard(
                  title: 'Mis Reportes',
                  subtitle: 'Historial y estado',
                  icon: Icons.assignment_outlined,
                  color: AppColors.info,
                  onTap: () => context.push(RouteNames.citizenMyReports),
                ),
                _ActionCard(
                  title: 'Mapa Urbano',
                  subtitle: 'Incidencias cercanas',
                  icon: Icons.map_outlined,
                  color: AppColors.warning,
                  onTap: () => context.push(RouteNames.citizenMap),
                ),
                _ActionCard(
                  title: 'Mi Perfil',
                  subtitle: 'Datos y ajustes',
                  icon: Icons.person_outline,
                  color: AppColors.forest,
                  onTap: () => context.push(RouteNames.citizenProfile),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Resumen de Estado de Reportes
            Text(
              'Estado de mis reportes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _StatusIndicator(
                      count: '0',
                      label: 'Pendientes',
                      color: AppColors.statusPending,
                    ),
                    _StatusIndicator(
                      count: '0',
                      label: 'En Proceso',
                      color: AppColors.statusInProgress,
                    ),
                    _StatusIndicator(
                      count: '0',
                      label: 'Resueltos',
                      color: AppColors.statusResolved,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_rounded),
            label: 'Reportar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
        onTap: (index) {
          if (index == 1) context.push(RouteNames.citizenCreateReport);
          if (index == 2) context.push(RouteNames.citizenMap);
          if (index == 3) context.push(RouteNames.citizenProfile);
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String count;
  final String label;
  final Color color;

  const _StatusIndicator({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
