import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user_entity.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Pantalla de registro de nuevos ciudadanos en EcoRoute.
///
/// Diseñada con arquitectura limpia, principios SOLID y componentes desacoplados.
/// La ilustración de cabecera (`Ilustration_register.jpg`) se ubica de forma elegante
/// exclusivamente en la parte superior, asegurando que el planeta Tierra y las hojas
/// enmarquen la cabecera, mientras que el formulario reposa sobre un fondo blanco limpio.
///
/// Ubicación: `lib/features/auth/presentation/views/register_screen.dart`
/// Capa: Presentation (Views)
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final phone = _phoneController.text.trim();
    final success = await ref.read(authViewModelProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: phone.isNotEmpty ? phone : null,
          role: UserRole.citizen,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada exitosamente! Bienvenido a EcoRoute.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    // Escucha de errores del ViewModel para feedback inmediato
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
          // 1. Imagen de cabecera panorámica ubicada ÚNICAMENTE en la parte superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Image.asset(
              AppAssets.registerIllustration,
              fit: BoxFit.cover,
              alignment: const Alignment(1.0, 0.1),
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),

          // 2. Contenido interactivo con scroll suave
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado superior con botón de retorno, logo oficial y titular
                  _RegisterHeader(
                    onBackPressed: () => context.pop(),
                  ),

                  const SizedBox(height: 12),

                  // Tarjeta blanca contenedora del formulario (fondo blanco continuo hasta la base)
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Nombre y Apellido
                          _RegisterInputField(
                            label: 'Nombre y Apellido',
                            hintText: 'Ej. Juan Pérez',
                            icon: Icons.person_outline_rounded,
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Ingrese su nombre y apellido';
                              }
                              if (val.trim().length < 3) {
                                return 'El nombre debe tener al menos 3 caracteres';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          // 2. Correo electrónico
                          _RegisterInputField(
                            label: 'Correo electrónico',
                            hintText: 'ejemplo@gmail.com',
                            icon: Icons.mail_outline_rounded,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Ingrese su correo electrónico';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Ingrese un correo electrónico válido';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          // 3. Teléfono de contacto (opcional)
                          _RegisterInputField(
                            label: 'Teléfono de contacto (opcional)',
                            hintText: 'Ej. +51 987654321',
                            icon: Icons.phone_outlined,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: (val) {
                              if (val != null &&
                                  val.trim().isNotEmpty &&
                                  val.trim().length < 7) {
                                return 'Ingrese un número telefónico válido';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          // 4. Contraseña
                          _RegisterInputField(
                            label: 'Contraseña',
                            hintText: 'Mínimo 6 caracteres',
                            icon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF64748B),
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Ingrese una contraseña';
                              }
                              if (val.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          // 5. Confirmar contraseña
                          _RegisterInputField(
                            label: 'Confirmar contraseña',
                            hintText: 'Repite la contraseña',
                            icon: Icons.lock_outline_rounded,
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF64748B),
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Confirme su contraseña';
                              }
                              if (val != _passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 22),

                          // Botón Crear Cuenta con flecha indicadora
                          _RegisterSubmitButton(
                            isLoading: authState.isLoading,
                            onPressed: _submit,
                          ),

                          const SizedBox(height: 16),

                          // Enlace inferior a inicio de sesión
                          _LoginRedirectText(
                            onTap: () => context.pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Componente de encabezado: Botón de retroceso, Logo y Titular visual.
///
/// Responsabilidad única: Renderizar la identidad y navegación superior en armonía
/// con la imagen de fondo panorámica.
class _RegisterHeader extends StatelessWidget {
  final VoidCallback onBackPressed;

  const _RegisterHeader({
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Logo EcoRoute oficial centrado y agrandado
          Center(
            child: Image.asset(
              AppAssets.logoInverted,
              height: 125,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                AppAssets.logo,
                height: 125,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Botón circular de volver en la esquina superior izquierda
          Positioned(
            left: 0,
            top: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBackPressed,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(225),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF334155),
                    size: 20,
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

/// Campo de entrada reutilizable y estandarizado para el formulario de registro.
///
/// Responsabilidad única: Renderizar la etiqueta y la caja de texto con sus estilos e iconos.
class _RegisterInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const _RegisterInputField({
    required this.label,
    required this.hintText,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta del campo
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),

        // Campo interactivo
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(
            fontSize: 14.5,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF64748B),
              size: 20,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF0E8A54),
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón de acción principal "Crear Cuenta".
///
/// Responsabilidad única: Renderizar el botón estilizado con texto centrado,
/// flecha derecha de navegación o indicador de progreso circular.
class _RegisterSubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _RegisterSubmitButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E8A54),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF0E8A54).withAlpha(160),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Crear Cuenta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Enlace inferior para usuarios ya registrados.
///
/// Responsabilidad única: Redirigir hacia la pantalla de inicio de sesión.
class _LoginRedirectText extends StatelessWidget {
  final VoidCallback onTap;

  const _LoginRedirectText({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿Ya tienes una cuenta? ',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Inicia sesión',
            style: TextStyle(
              color: Color(0xFF0E8A54),
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}
