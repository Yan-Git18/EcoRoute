import 'package:flutter/material.dart';

/// Botón de acceso a notificaciones unificado para EcoRoute.
/// Capa: Core (Widgets)
class EcoNotificationButton extends StatelessWidget {
  static const maxBadgeCount = 99;

  final VoidCallback onTap;
  final int badgeCount;
  final double size;
  final String tooltip;

  const EcoNotificationButton({
    super.key,
    required this.onTap,
    required this.badgeCount,
    this.size = 44,
    this.tooltip = 'Notificaciones',
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF0F172A),
                size: 22,
              ),
              if (badgeCount > 0)
                PositionedDirectional(
                  top: -2,
                  end: -2,
                  child: Badge(
                    backgroundColor: const Color(0xFFDC2626),
                    textColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    label: Text(
                      badgeCount > maxBadgeCount
                          ? '$maxBadgeCount+'
                          : '$badgeCount',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
