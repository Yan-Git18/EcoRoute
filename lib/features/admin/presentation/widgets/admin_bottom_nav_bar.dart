import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/eco_bottom_nav_bar.dart';
import '../viewmodels/admin_reports_viewmodel.dart';

/// Barra de navegación inferior para el rol de Administrador Municipal.
///
/// Principio DRY: Delega en el componente base [EcoBottomNavBar].
/// Ubicación: `lib/features/admin/presentation/widgets/admin_bottom_nav_bar.dart`
/// Capa: Presentation (Widgets Admin)
class AdminBottomNavBar extends ConsumerWidget {
  /// Índice del tab activo actual:
  /// 0: Inicio / Dashboard, 1: Reportes, 2: Mapa, 3: Cuadrillas
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

  void _handleTap(BuildContext context, int index) {
    if (onTabSelected != null) {
      onTabSelected!(index);
      return;
    }

    if (index == currentIndex) return;

    switch (index) {
      case 0:
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RouteNames.adminDashboard);
        }
        break;
      case 1:
        context.push(RouteNames.adminReports);
        break;
      case 2:
        context.push(RouteNames.adminLiveMap);
        break;
      case 3:
        context.push(RouteNames.adminTeams);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(adminReportsViewModelProvider).pendingCount;

    return EcoBottomNavBar(
      currentIndex: currentIndex,
      items: [
        EcoBottomNavItem(
          label: 'Inicio',
          activeIcon: Icons.dashboard_rounded,
          inactiveIcon: Icons.dashboard_outlined,
          onTap: () => _handleTap(context, 0),
        ),
        EcoBottomNavItem(
          label: 'Reportes',
          activeIcon: Icons.assignment_rounded,
          inactiveIcon: Icons.assignment_outlined,
          badgeCount: pendingCount > 0 ? pendingCount : null,
          onTap: () => _handleTap(context, 1),
        ),
        EcoBottomNavItem(
          label: 'Mapa',
          activeIcon: Icons.map_rounded,
          inactiveIcon: Icons.map_outlined,
          onTap: () => _handleTap(context, 2),
        ),
        EcoBottomNavItem(
          label: 'Cuadrillas',
          activeIcon: Icons.groups_rounded,
          inactiveIcon: Icons.groups_outlined,
          onTap: () => _handleTap(context, 3),
        ),
      ],
    );
  }
}
