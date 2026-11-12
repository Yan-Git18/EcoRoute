import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/eco_bottom_nav_bar.dart';

/// Barra de navegación inferior para el rol Ciudadano.
///
/// Principio DRY: Delega en el componente base [EcoBottomNavBar].
/// Ubicación: `lib/features/citizen/presentation/widgets/citizen_bottom_nav_bar.dart`
/// Capa: Presentation (Widgets Citizen)
class CitizenBottomNavBar extends StatelessWidget {
  /// Índice del tab activo actual:
  /// 0: Inicio, 1: Mapa, 2: Reportar, 3: Mis reportes, 4: Perfil
  final int currentIndex;

  const CitizenBottomNavBar({super.key, required this.currentIndex});

  static const Color activeGreen = Color(0xFF0A5835);
  static const Color inactiveColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return EcoBottomNavBar(
      currentIndex: currentIndex,
      items: [
        EcoBottomNavItem(
          label: 'Inicio',
          activeIcon: Icons.home_rounded,
          inactiveIcon: Icons.home_outlined,
          onTap: () {
            if (currentIndex != 0) context.go(RouteNames.citizenHome);
          },
        ),
        EcoBottomNavItem(
          label: 'Mapa',
          activeIcon: Icons.map_rounded,
          inactiveIcon: Icons.map_outlined,
          onTap: () {
            if (currentIndex != 1) context.push(RouteNames.citizenMap);
          },
        ),
        EcoBottomNavItem(
          label: 'Reportar',
          activeIcon: Icons.add_rounded,
          inactiveIcon: Icons.add_rounded,
          onTap: () => context.push(RouteNames.citizenCreateReport),
          customWidget: InkWell(
            onTap: () => context.push(RouteNames.citizenCreateReport),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: activeGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: activeGreen.withAlpha(80),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Reportar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        EcoBottomNavItem(
          label: 'Mis reportes',
          activeIcon: Icons.assignment_rounded,
          inactiveIcon: Icons.assignment_outlined,
          onTap: () {
            if (currentIndex != 3) context.go(RouteNames.citizenMyReports);
          },
        ),
        EcoBottomNavItem(
          label: 'Perfil',
          activeIcon: Icons.person_rounded,
          inactiveIcon: Icons.person_outline_rounded,
          onTap: () {
            if (currentIndex != 4) context.push(RouteNames.citizenProfile);
          },
        ),
      ],
    );
  }
}
