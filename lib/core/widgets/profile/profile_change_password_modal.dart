import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../theme/app_colors.dart';
import '../eco_bottom_sheet.dart';

/// Modal interactivo para solicitud de restablecimiento de contraseña.
///
/// Principio DRY: Compartido entre CitizenProfileScreen y StaffProfileScreen.
/// Ubicación: `lib/core/widgets/profile/profile_change_password_modal.dart`
/// Capa: Core (Widgets / Profile)
class ProfileChangePasswordModal {
  static void show(
    BuildContext context,
    WidgetRef ref, {
    required String email,
  }) {
    EcoBottomSheet.show(
      context: context,
      title: 'Cambiar contraseña',
      children: [
        const Text(
          'Por seguridad, te enviaremos un enlace de restablecimiento seguro a tu correo registrado.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(authViewModelProvider.notifier)
                  .sendPasswordResetEmail(email);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? AppColors.primary : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: Text(
                      success
                          ? 'Enlace de restablecimiento enviado a $email'
                          : 'No se pudo enviar el correo de recuperación.',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Enviar enlace de restablecimiento',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
          ),
        ),
      ],
    );
  }
}
