import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';

/// Capa: Presentation (Widgets)
class CitizenBottomNavBar extends StatelessWidget {
  /// Índice del tab activo actual:
  /// 0: Inicio, 1: Mapa, 2: Reportar, 3: Mis reportes, 4: Perfil
  final int currentIndex;

  const CitizenBottomNavBar({super.key, required this.currentIndex});

  static const Color activeGreen = Color(0xFF0A5835);
  static const Color inactiveColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // 0: Inicio
              Expanded(
                child: _NavBarTab(
                  label: 'Inicio',
                  icon: currentIndex == 0
                      ? Icons.home_rounded
                      : Icons.home_outlined,
                  isSelected: currentIndex == 0,
                  activeColor: activeGreen,
                  inactiveColor: inactiveColor,
                  onTap: () {
                    if (currentIndex != 0) context.go(RouteNames.citizenHome);
                  },
                ),
              ),

              // 1: Mapa
              Expanded(
                child: _NavBarTab(
                  label: 'Mapa',
                  icon: currentIndex == 1
                      ? Icons.map_rounded
                      : Icons.map_outlined,
                  isSelected: currentIndex == 1,
                  activeColor: activeGreen,
                  inactiveColor: inactiveColor,
                  onTap: () {
                    if (currentIndex != 1) context.push(RouteNames.citizenMap);
                  },
                ),
              ),

              // 2: Reportar (Botón central destacado)
              Expanded(
                child: InkWell(
                  onTap: () => context.push(RouteNames.citizenCreateReport),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
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
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Reportar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3: Mis reportes
              Expanded(
                child: _NavBarTab(
                  label: 'Mis reportes',
                  icon: currentIndex == 3
                      ? Icons.assignment_rounded
                      : Icons.assignment_outlined,
                  isSelected: currentIndex == 3,
                  activeColor: activeGreen,
                  inactiveColor: inactiveColor,
                  onTap: () {
                    if (currentIndex != 3) {
                      context.go(RouteNames.citizenMyReports);
                    }
                  },
                ),
              ),

              // 4: Perfil
              Expanded(
                child: _NavBarTab(
                  label: 'Perfil',
                  icon: currentIndex == 4
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  isSelected: currentIndex == 4,
                  activeColor: activeGreen,
                  inactiveColor: inactiveColor,
                  onTap: () {
                    if (currentIndex != 4) {
                      context.push(RouteNames.citizenProfile);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
