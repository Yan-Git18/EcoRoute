import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user_entity.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Pantalla de inicio de sesión de EcoRoute con diseño limpio e ilustración de fondo.
///
/// Ubicación: `lib/features/auth/presentation/views/login_screen.dart`
/// Capa: Presentation (Views)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showDemoRoles = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authViewModelProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final size = MediaQuery.of(context).size;
    final topLogoSpacing = (size.height * 0.08).clamp(50.0, 80.0);

    // Escuchar errores para notificar al usuario
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Imagen de Fondo a Pantalla Completa (Ilustration_login.jpeg)
          Positioned.fill(
            child: Image.asset(
              AppAssets.loginIllustration,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),

          // 2. Contenido interactivo con scroll para evitar desbordes con teclado
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: topLogoSpacing),

                      // Logo EcoRoute Invertido para fondo claro (logo_invertido.webp)
                      Center(
                        child: Image.asset(
                          AppAssets.logoInverted,
                          height: 160,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              AppAssets.logo,
                              height: 160,
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Slogan oficial
                      const Text(
                        'Juntos por ciudades más limpias',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forest,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Campo: Correo electrónico
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Correo electrónico',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14.5,
                            ),
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              color: Color(0xFF475569),
                              size: 22,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.8,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Por favor ingrese su correo';
                            }
                            if (!val.contains('@')) {
                              return 'Ingrese un correo electrónico válido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo: Contraseña
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Contraseña',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14.5,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF475569),
                              size: 22,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF64748B),
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.8,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Enlace: ¿Olvidaste tu contraseña?
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                          ),
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Botón: Iniciar sesión (Píldora verde esmeralda)
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: AppColors.primary.withAlpha(90),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Iniciar sesión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Fila con separadores: ¿No tienes cuenta? Regístrate
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: const Color(0xFFCBD5E1).withAlpha(120),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '¿No tienes cuenta? ',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      context.push(RouteNames.register),
                                  child: const Text(
                                    'Regístrate',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: const Color(0xFFCBD5E1).withAlpha(120),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Acceso de prueba rápida para desarrollador (discreto y plegable)
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showDemoRoles = !_showDemoRoles;
                            });
                          },
                          icon: Icon(
                            _showDemoRoles
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.flash_on_rounded,
                            size: 16,
                            color: AppColors.primaryDark.withAlpha(160),
                          ),
                          label: Text(
                            _showDemoRoles
                                ? 'Ocultar roles demo'
                                : 'Roles de prueba demo',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryDark.withAlpha(160),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      if (_showDemoRoles) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _DemoRoleChip(
                              label: 'Ciudadano',
                              color: AppColors.primary,
                              onTap: () {
                                ref
                                    .read(authViewModelProvider.notifier)
                                    .setDemoRole(UserRole.citizen);
                              },
                            ),
                            _DemoRoleChip(
                              label: 'Personal',
                              color: AppColors.info,
                              onTap: () {
                                ref
                                    .read(authViewModelProvider.notifier)
                                    .setDemoRole(UserRole.staff);
                              },
                            ),
                            _DemoRoleChip(
                              label: 'Admin',
                              color: AppColors.forest,
                              onTap: () {
                                ref
                                    .read(authViewModelProvider.notifier)
                                    .setDemoRole(UserRole.admin);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoRoleChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DemoRoleChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(90)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
