import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref
        .read(authViewModelProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final resetFormKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            content: Form(
              key: resetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono decorativo superior
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft.withAlpha(160),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Título
                  const Text(
                    'Recuperar Contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Mensaje de recuperar contraseña
                  const Text(
                    'Ingresa el correo electrónico asociado a tu cuenta de EcoRoute y te enviaremos un enlace seguro para crear una nueva contraseña.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo de texto para el correo
                  TextFormField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ejemplo@gmail.com',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.8,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 1.4,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 1.8,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'Ingresa un correo electrónico válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Nota informativa amigable
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: AppColors.textSecondary.withAlpha(160),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Revisa tu bandeja de entrada o spam tras enviar.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!resetFormKey.currentState!.validate()) return;
                              setDialogState(() => isSubmitting = true);

                              final email = resetEmailController.text.trim();
                              final success = await ref
                                  .read(authViewModelProvider.notifier)
                                  .sendPasswordResetEmail(email);

                              if (!context.mounted) return;
                              Navigator.of(dialogContext).pop();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        success
                                            ? Icons.mark_email_read_outlined
                                            : Icons.error_outline_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          success
                                              ? 'Enlace enviado a $email. Revisa tu correo.'
                                              : (ref.read(authViewModelProvider).errorMessage ??
                                                  'No se pudo enviar el correo de recuperación.'),
                                          style: const TextStyle(fontSize: 13.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: success
                                      ? AppColors.forest
                                      : AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shadowColor: AppColors.primary.withAlpha(80),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Enviar enlace',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
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
                          textInputAction: TextInputAction.next,
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
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
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
                          onPressed: _showForgotPasswordDialog,
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
                      const SizedBox(height: 24),
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
