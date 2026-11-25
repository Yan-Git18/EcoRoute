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
  static const _routes = [
    RouteNames.adminDashboard,
    RouteNames.adminReports,
    RouteNames.adminLiveMap,
    RouteNames.adminTeams,
  ];

  /// Índice del tab activo actual:
  /// 0: Inicio, 1: Reportes, 2: Mapa, 3: Equipo, null: fuera del menú.
  final int? currentIndex;
  final ValueChanged<int>? onTabSelected;

  const AdminBottomNavBar({super.key, this.currentIndex, this.onTabSelected});

  void _handleTap(BuildContext context, int index) {
    if (onTabSelected != null) {
      onTabSelected!(index);
      return;
    }

    if (index != currentIndex) {
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount =
        ref.watch(adminReportsViewModelProvider).totals?.pending ?? 0;

    return EcoBottomNavBar(
      currentIndex: currentIndex ?? -1,
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
          label: 'Equipo',
          activeIcon: Icons.groups_rounded,
          inactiveIcon: Icons.groups_outlined,
          onTap: () => _handleTap(context, 3),
        ),
      ],
    );
  }
}
