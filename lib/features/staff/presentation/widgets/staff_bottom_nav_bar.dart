import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/eco_bottom_nav_bar.dart';

/// Barra de navegación inferior para el personal de limpieza.
///
/// Principio DRY: Delega en el componente base [EcoBottomNavBar].
/// Ubicación: `lib/features/staff/presentation/widgets/staff_bottom_nav_bar.dart`
/// Capa: Presentation (Widgets Staff)
class StaffBottomNavBar extends StatelessWidget {
  /// Índice activo: 0: Inicio, 1: Mapa, 2: Tareas, 3: Rutas, 4: Perfil
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  const StaffBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

  void _select(BuildContext context, int index) {
    if (index != currentIndex && GoRouter.maybeOf(context) != null) {
      context.go(
        const [
          RouteNames.staffHome,
          RouteNames.staffRouteMap,
          RouteNames.staffTasks,
          RouteNames.staffCollectionRoutes,
          RouteNames.staffProfile,
        ][index],
      );
    } else if (index == currentIndex) {
      onTabSelected?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EcoBottomNavBar(
      currentIndex: currentIndex,
      items: [
        EcoBottomNavItem(
          label: 'Inicio',
          activeIcon: Icons.home_rounded,
          inactiveIcon: Icons.home_outlined,
          onTap: () => _select(context, 0),
        ),
        EcoBottomNavItem(
          label: 'Mapa',
          activeIcon: Icons.map_rounded,
          inactiveIcon: Icons.map_outlined,
          onTap: () => _select(context, 1),
        ),
        EcoBottomNavItem(
          label: 'Tareas',
          activeIcon: Icons.assignment_rounded,
          inactiveIcon: Icons.assignment_outlined,
          onTap: () => _select(context, 2),
        ),
        EcoBottomNavItem(
          label: 'Rutas',
          activeIcon: Icons.alt_route,
          inactiveIcon: Icons.route_outlined,
          onTap: () => _select(context, 3),
        ),
        EcoBottomNavItem(
          label: 'Perfil',
          activeIcon: Icons.person_rounded,
          inactiveIcon: Icons.person_outline_rounded,
          onTap: () => _select(context, 4),
        ),
      ],
    );
  }
}
