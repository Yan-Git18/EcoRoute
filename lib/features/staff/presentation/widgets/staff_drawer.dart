import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/eco_logo_badge.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/staff_home_viewmodel.dart';

/// Menú lateral (Drawer) para el Personal de Limpieza.
/// Capa: Presentation (Widgets Staff)
class StaffDrawer extends ConsumerWidget {
  final String staffName;
  final String? email;

  const StaffDrawer({
    super.key,
    required this.staffName,
    this.email,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const EcoLogoBadge(size: 44, iconSize: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EcoRoute Personal',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          staffName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFF1F5F9)),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: Color(0xFF0A5835)),
              title: const Text(
                'Panel de Operaciones',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
              title: const Text('Actualizar tareas'),
              onTap: () {
                Navigator.pop(context);
                ref.read(staffHomeViewModelProvider.notifier).refresh();
              },
            ),
            const Spacer(),
            const Divider(color: Color(0xFFF1F5F9)),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(authViewModelProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
