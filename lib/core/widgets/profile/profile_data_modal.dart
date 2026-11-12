import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../eco_bottom_sheet.dart';

/// Fila individual de información para modales de perfil.
class ProfileDataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileDataRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF475569), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Modal genérico de "Mis datos personales" para cualquier rol de usuario.
///
/// Principio DRY y SRP: Reutilizado en CitizenProfileScreen y StaffProfileScreen.
/// Ubicación: `lib/core/widgets/profile/profile_data_modal.dart`
/// Capa: Core (Widgets / Profile)
class ProfileDataModal {
  static void show(
    BuildContext context, {
    required String name,
    required String email,
    required String phone,
    required String roleLabel,
  }) {
    EcoBottomSheet.show(
      context: context,
      title: 'Mis datos personales',
      children: [
        ProfileDataRow(
          icon: Icons.person_rounded,
          label: 'Nombre completo',
          value: name,
        ),
        const SizedBox(height: 14),
        ProfileDataRow(
          icon: Icons.email_rounded,
          label: 'Correo electrónico',
          value: email,
        ),
        const SizedBox(height: 14),
        ProfileDataRow(
          icon: Icons.phone_rounded,
          label: 'Teléfono',
          value: phone,
        ),
        const SizedBox(height: 14),
        ProfileDataRow(
          icon: Icons.badge_rounded,
          label: 'Rol en la plataforma',
          value: roleLabel,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Cerrar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}
