import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Campo de texto interactivo reutilizable para formularios de autenticación.
///
/// Principio DRY y SRP: Unifica el estilo visual, bordes redondeados, validaciones
/// y manejo de iconos entre [LoginScreen] y [RegisterScreen].
/// Ubicación: `lib/core/widgets/auth/auth_text_field.dart`
/// Capa: Core (Widgets)
class AuthTextField extends StatelessWidget {
  final String? label;
  final String hintText;
  final IconData? prefixIcon;
  final IconData? icon;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Color fillColor;
  final bool hasElevation;

  const AuthTextField({
    super.key,
    this.label,
    required this.hintText,
    this.prefixIcon,
    this.icon,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onFieldSubmitted,
    this.fillColor = const Color(0xFFF8FAFC),
    this.hasElevation = false,
  }) : assert(prefixIcon != null || icon != null, 'Debe especificar icon o prefixIcon');

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = prefixIcon ?? icon!;
    final field = TextFormField(
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
          effectiveIcon,
          color: const Color(0xFF64748B),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
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
    );

    final content = hasElevation
        ? Container(
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
            child: field,
          )
        : field;

    if (label == null) {
      return content;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        content,
      ],
    );
  }
}
