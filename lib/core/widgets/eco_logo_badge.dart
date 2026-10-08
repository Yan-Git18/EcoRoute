import 'package:flutter/material.dart';

/// Insignia circular oficial con el ícono ecológico de EcoRoute.
/// Capa: Core (Widgets)
class EcoLogoBadge extends StatelessWidget {
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;

  const EcoLogoBadge({
    super.key,
    this.size = 38,
    this.iconSize = 22,
    this.backgroundColor = const Color(0xFF0A5835),
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.eco_rounded,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }
}
