import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';

/// Menú de navegación inferior global y unificado para el rol Ciudadano.
///
/// Mantiene consistencia visual, iconos y orden de opciones idéntico en toda la aplicación.
///
/// Ubicación: `lib/features/citizen/presentation/widgets/citizen_bottom_nav_bar.dart`
/// Capa: Presentation (Widgets)
class CitizenBottomNavBar extends StatelessWidget {
  /// Índice del tab activo actual:
  /// 0: Inicio, 1: Mapa, 2: Reportar, 3: Mis reportes, 4: Perfil
  final int currentIndex;

  const CitizenBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 11.5,
        unselectedFontSize: 11.5,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            activeIcon: Icon(Icons.add_circle_rounded),
            label: 'Reportar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Mis reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
        onTap: (index) {
          if (index == currentIndex) return;

          switch (index) {
            case 0:
              context.go(RouteNames.citizenHome);
              break;
            case 1:
              context.push(RouteNames.citizenMap);
              break;
            case 2:
              context.push(RouteNames.citizenCreateReport);
              break;
            case 3:
              context.go(RouteNames.citizenMyReports);
              break;
            case 4:
              context.push(RouteNames.citizenProfile);
              break;
          }
        },
      ),
    );
  }
}
