import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/profile/profile_widgets.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../widgets/citizen_bottom_nav_bar.dart';

/// Pantalla de Perfil de Usuario para el rol Ciudadano.
///
/// Diseño fiel al mockup de referencia:
/// - Título centrado "Mi perfil"
/// - Avatar circular con fondo gris suave y silueta de usuario
/// - Nombre y correo electrónico centrados
/// - Tarjeta de opciones: Mis datos, Cambiar contraseña, Notificaciones, Acerca de EcoRoute (sin opción de Idioma)
/// - Opción destacada en rojo "Cerrar sesión" con confirmación de seguridad
/// - Barra de navegación inferior `CitizenBottomNavBar` en la pestaña de Perfil
///
/// Principios aplicados: DRY y SRP mediante delegación en [ProfileDataModal],
/// [ProfileChangePasswordModal], [ProfileNotificationsModal] y [ProfileLogoutDialog].
/// Ubicación: `lib/features/citizen/presentation/views/citizen_profile_screen.dart`
/// Capa: Presentation (Views)
class CitizenProfileScreen extends ConsumerWidget {
  const CitizenProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : 'Alejandro Rabanal';
    final displayEmail = user?.email.isNotEmpty == true
        ? user!.email
        : 'alejandro@gmail.com';

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
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.person_rounded,
                            size: 58,
                            color: Color(0xFF8C98A9),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 58,
                        color: Color(0xFF8C98A9),
                      ),
              ),
            ),
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
                    onTap: () => _openMyDataModal(context, user),
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
                    onTap: () => _openNotificationsModal(context),
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

  void _openMyDataModal(BuildContext context, UserEntity? user) {
    ProfileDataModal.show(
      context,
      name: user?.name.isNotEmpty == true ? user!.name : 'Alejandro Rabanal',
      email: user?.email.isNotEmpty == true ? user!.email : 'alejandro@gmail.com',
      phone: user?.phoneNumber ?? '+51 987 654 321',
      roleLabel: 'Ciudadano Activo',
    );
  }

  void _openChangePasswordModal(BuildContext context, WidgetRef ref, String email) {
    ProfileChangePasswordModal.show(context, ref, email: email);
  }

  void _openNotificationsModal(BuildContext context) {
    ProfileNotificationsModal.show(
      context,
      options: const [
        NotificationOptionItem(
          title: 'Actualizaciones de reportes',
          subtitle: 'Notificarme cuando mi reporte sea asignado o resuelto.',
          initialValue: true,
        ),
        NotificationOptionItem(
          title: 'Camión recolector cerca',
          subtitle: 'Alertar cuando el camión esté a menos de 500 metros.',
          initialValue: true,
        ),
        NotificationOptionItem(
          title: 'Campañas y noticias ambientales',
          subtitle: 'Avisos sobre jornadas de reciclaje y actividades cívicas.',
          initialValue: false,
        ),
      ],
    );
  }
}
