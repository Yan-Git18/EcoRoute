import 'package:flutter/material.dart';

/// Modelo descriptivo de un elemento de la barra de navegación inferior.
class EcoBottomNavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final VoidCallback onTap;
  final int? badgeCount;
  final Widget? customWidget;

  const EcoBottomNavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.onTap,
    this.badgeCount,
    this.customWidget,
  });
}

/// Barra de navegación inferior estandarizada de EcoRoute.
///
/// Principio DRY y OCP: Centraliza la estructura visual, sombras, bordes y pestañas
/// para Ciudadano, Personal y Administrador, soportando botones centrales personalizados
/// y badges reactivos de notificaciones o incidencias pendientes.
/// Ubicación: `lib/core/widgets/eco_bottom_nav_bar.dart`
/// Capa: Core (Widgets)
class EcoBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<EcoBottomNavItem> items;
  final Color activeColor;
  final Color inactiveColor;

  const EcoBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    this.activeColor = const Color(0xFF0A5835),
    this.inactiveColor = const Color(0xFF64748B),
  });

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
        bottom: true,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++)
                  Expanded(
                    child: items[i].customWidget ??
                        _EcoNavTab(
                          label: items[i].label,
                          icon: currentIndex == i
                              ? items[i].activeIcon
                              : items[i].inactiveIcon,
                          isSelected: currentIndex == i,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          badgeCount: items[i].badgeCount,
                          onTap: items[i].onTap,
                        ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EcoNavTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final int? badgeCount;
  final VoidCallback onTap;

  const _EcoNavTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    this.badgeCount,
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 24),
              if (badgeCount != null && badgeCount! > 0)
                Positioned(
                  top: -4,
                  right: -7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                    child: Text(
                      badgeCount! > 99 ? '99+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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

