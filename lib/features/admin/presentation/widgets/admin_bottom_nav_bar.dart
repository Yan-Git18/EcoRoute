import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../viewmodels/admin_reports_viewmodel.dart';

/// Barra de navegación inferior para el rol de Administrador Municipal.
///
/// Ubicación: `lib/features/admin/presentation/widgets/admin_bottom_nav_bar.dart`
/// Capa: Presentation (Widgets Admin)
class AdminBottomNavBar extends ConsumerWidget {
  /// Índice del tab activo actual:
  /// 0: Inicio / Dashboard
  /// 1: Reportes
  /// 2: Mapa
  /// 3: Cuadrillas
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

  static const Color activeGreen = Color(0xFF0A5835);
  static const Color inactiveColor = Color(0xFF64748B);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monitoreo en Mapa Urbano en Tiempo Real (Fase 2).'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gestión de Cuadrillas y Flota Municipal (Fase 3).'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(adminReportsViewModelProvider).pendingCount;

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
                child: _AdminNavTab(
                  label: 'Inicio',
                  icon: currentIndex == 0
                      ? Icons.dashboard_rounded
                      : Icons.dashboard_outlined,
                  isSelected: currentIndex == 0,
                  activeColor: activeGreen,
                  inactiveColor: inactiveColor,
                  onTap: () => _handleTap(context, 0),
                ),
              ),

              // 1: Reportes (con Badge reactivo si hay pendientes)
              Expanded(
                child: _AdminNavTab(
                  label: 'Reportes',
                  icon: currentIndex == 1
                      ? Icons.assignment_rounded
                      : Icons.assignment_outlined,
                  isSelected: currentIndex == 1,
                  badgeCount: pendingCount > 0 ? pendingCount : null,
                  activeColor: activeGreen,
                  inactiveColor: inactiveColor,
                  onTap: () => _handleTap(context, 1),
                ),
              ),

              // 2: Mapa
              Expanded(
                child: _AdminNavTab(
                  label: 'Mapa',
                  icon: currentIndex == 2
                      ? Icons.map_rounded
                      : Icons.map_outlined,
                  isSelected: currentIndex == 2,
                  activeColor: activeGreen,
                  inactiveColor: inactiveColor,
                  onTap: () => _handleTap(context, 2),
                ),
              ),

              // 3: Cuadrillas
              Expanded(
                child: _AdminNavTab(
                  label: 'Cuadrillas',
                  icon: currentIndex == 3
                      ? Icons.local_shipping_rounded
                      : Icons.local_shipping_outlined,
                  isSelected: currentIndex == 3,
                  activeColor: activeGreen,
                  inactiveColor: inactiveColor,
                  onTap: () => _handleTap(context, 3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final int? badgeCount;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _AdminNavTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.badgeCount,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;

    Widget iconWidget = Icon(icon, color: color, size: 24);

    if (badgeCount != null && badgeCount! > 0) {
      iconWidget = Badge(
        label: Text(
          '$badgeCount',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFE11D48),
        offset: const Offset(8, -4),
        child: iconWidget,
      );
    }

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
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
