import 'package:flutter/material.dart';

/// Capa: Presentation (Widgets)
class StaffBottomNavBar extends StatelessWidget {
  /// Índice activo: 0: Inicio, 1: Mapa, 2: Tareas, 3: Perfil
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  const StaffBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

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
                child: _StaffNavTab(
                  label: 'Inicio',
                  icon: currentIndex == 0
                      ? Icons.home_rounded
                      : Icons.home_outlined,
                  isSelected: currentIndex == 0,
                  activeColor: activeGreen,
                  inactiveColor: inactiveColor,
                  onTap: () => onTabSelected?.call(0),
                ),
              ),

              // 1: Mapa
              Expanded(
                child: _StaffNavTab(
                  label: 'Mapa',
                  icon: currentIndex == 1
                      ? Icons.map_rounded
                      : Icons.map_outlined,
                  isSelected: currentIndex == 1,
                  activeColor: activeGreen,
                  inactiveColor: inactiveColor,
                  onTap: () => onTabSelected?.call(1),
                ),
              ),

              // 2: Tareas
              Expanded(
                child: _StaffNavTab(
                  label: 'Tareas',
                  icon: currentIndex == 2
                      ? Icons.assignment_rounded
                      : Icons.assignment_outlined,
                  isSelected: currentIndex == 2,
                  activeColor: activeGreen,
                  inactiveColor: inactiveColor,
                  onTap: () => onTabSelected?.call(2),
                ),
              ),

              // 3: Perfil
              Expanded(
                child: _StaffNavTab(
                  label: 'Perfil',
                  icon: currentIndex == 3
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  isSelected: currentIndex == 3,
                  activeColor: activeGreen,
                  inactiveColor: inactiveColor,
                  onTap: () => onTabSelected?.call(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffNavTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _StaffNavTab({
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
