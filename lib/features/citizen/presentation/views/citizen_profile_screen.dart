import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/profile/profile_widgets.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../widgets/citizen_bottom_nav_bar.dart';
import '../widgets/citizen_notification_preferences_sheet.dart';
import '../widgets/citizen_profile_editor.dart';

/// Pantalla de Perfil de Usuario para el rol Ciudadano.
///
class CitizenProfileScreen extends ConsumerWidget {
  const CitizenProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : 'Ciudadano EcoRoute';
    final displayEmail = user?.email.isNotEmpty == true
        ? user!.email
        : 'Sin correo registrado';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Mi perfil',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // 1. Avatar Circular con silueta gris
            Center(child: CitizenProfileAvatar(url: user?.photoUrl, size: 96)),
            const SizedBox(height: 14),

            // 2. Nombre del usuario
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),

            // 3. Correo electrónico
            Text(
              displayEmail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Tarjeta blanca con opciones de menú
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Mis datos
                  EcoProfileMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Mis datos',
                    onTap: () {
                      if (user != null) CitizenProfileEditor.show(context, user);
                    },
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    endIndent: 16,
                    color: Color(0xFFF1F5F9),
                  ),

                  // Cambiar contraseña
                  EcoProfileMenuItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Cambiar contraseña',
                    onTap: () => _openChangePasswordModal(context, ref, displayEmail),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    endIndent: 16,
                    color: Color(0xFFF1F5F9),
                  ),

                  // Notificaciones
                  EcoProfileMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notificaciones',
                    onTap: () {
                      if (user != null) {
                        CitizenNotificationPreferencesSheet.show(context, user.id);
                      }
                    },
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    endIndent: 16,
                    color: Color(0xFFF1F5F9),
                  ),

                  // Acerca de EcoRoute
                  EcoProfileMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Acerca de EcoRoute',
                    onTap: () => AboutAppModal.show(context),
                  ),

                  const SizedBox(height: 6),

                  // Cerrar sesión
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      onTap: () => ProfileLogoutDialog.show(
                        context,
                        onConfirm: () => ref.read(authViewModelProvider.notifier).logout(),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFEF4444),
                              size: 22,
                            ),
                            SizedBox(width: 14),
                            Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const CitizenBottomNavBar(currentIndex: 4),
    );
  }

  void _openChangePasswordModal(BuildContext context, WidgetRef ref, String email) {
    ProfileChangePasswordModal.show(context, ref, email: email);
  }

}
