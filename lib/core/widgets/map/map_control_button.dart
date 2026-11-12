import 'package:flutter/material.dart';

/// Botón circular flotante translúcido para controles y acciones en mapas urbanos.
///
/// Principio DRY y SRP: Reutilizado en [Step3LocationView] y [StaffRouteMapScreen].
/// Ubicación: `lib/core/widgets/map/map_control_button.dart`
/// Capa: Core (Widgets)
class MapControlButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  const MapControlButton({
    super.key,
    required this.icon,
    this.iconColor = const Color(0xFF334155),
    required this.tooltip,
    required this.onPressed,
    this.size = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(240),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(
              icon,
              size: (size * 0.55).clamp(18.0, 22.0),
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

