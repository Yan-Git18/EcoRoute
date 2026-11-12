import 'package:flutter/material.dart';
import '../../../../core/widgets/eco_bottom_nav_bar.dart';

/// Barra de navegación inferior para el personal de limpieza.
///
/// Principio DRY: Delega en el componente base [EcoBottomNavBar].
/// Ubicación: `lib/features/staff/presentation/widgets/staff_bottom_nav_bar.dart`
/// Capa: Presentation (Widgets Staff)
class StaffBottomNavBar extends StatelessWidget {
  /// Índice activo: 0: Inicio, 1: Mapa, 2: Tareas, 3: Perfil
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  const StaffBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return EcoBottomNavBar(
      currentIndex: currentIndex,
      items: [
        EcoBottomNavItem(
          label: 'Inicio',
          activeIcon: Icons.home_rounded,
          inactiveIcon: Icons.home_outlined,
          onTap: () => onTabSelected?.call(0),
        ),
        EcoBottomNavItem(
          label: 'Mapa',
          activeIcon: Icons.map_rounded,
          inactiveIcon: Icons.map_outlined,
          onTap: () => onTabSelected?.call(1),
        ),
        EcoBottomNavItem(
          label: 'Tareas',
          activeIcon: Icons.assignment_rounded,
          inactiveIcon: Icons.assignment_outlined,
          onTap: () => onTabSelected?.call(2),
        ),
        EcoBottomNavItem(
          label: 'Perfil',
          activeIcon: Icons.person_rounded,
          inactiveIcon: Icons.person_outline_rounded,
          onTap: () => onTabSelected?.call(3),
        ),
      ],
    );
  }
}
