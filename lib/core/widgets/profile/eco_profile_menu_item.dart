import 'package:flutter/material.dart';

/// Elemento de menú individual reutilizable para opciones de perfil y configuración.
///
/// Principio SRP: Responsabilidad única de renderizar una fila interactiva de opción.
/// Ubicación: `lib/core/widgets/profile/eco_profile_menu_item.dart`
/// Capa: Core (Widgets / Profile)
class EcoProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  final Widget? trailing;

  const EcoProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = const Color(0xFF334155),
    this.textColor = const Color(0xFF0F172A),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Color(0xFF94A3B8),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

