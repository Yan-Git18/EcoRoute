import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../eco_bottom_sheet.dart';

/// Modal informativo sobre la aplicación EcoRoute.
///
/// Principio SRP: Presenta la versión y propósito general de la plataforma.
/// Ubicación: `lib/core/widgets/profile/about_app_modal.dart`
/// Capa: Core (Widgets / Profile)
class AboutAppModal {
  static void show(BuildContext context) {
    EcoBottomSheet.show(
      context: context,
      title: 'Acerca de EcoRoute',
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: AppColors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'EcoRoute',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Versión 1.0.0 • Gestión Inteligente de Residuos',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'EcoRoute conecta a la comunidad y a los operarios municipales para reportar, monitorear y recolectar residuos de forma ágil y transparente.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: Color(0xFF475569),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Entendido'),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
