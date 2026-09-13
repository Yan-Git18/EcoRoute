import 'package:flutter/material.dart';

/// Paleta de colores de EcoRoute.
/// Lema: "Juntos por ciudades más limpias"
/// 
/// Ubicación: `lib/core/theme/app_colors.dart`
/// Capa: Core (Theme)
class AppColors {
  AppColors._();

  // Primarios ecológicos (Esmeralda / Sostenibilidad)
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF065F46); // Emerald 800
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400
  static const Color primarySoft = Color(0xFFD1FAE5); // Emerald 100

  // Secundarios y Acentos (Menta y Naturaleza)
  static const Color secondary = Color(0xFF10B981); // Emerald 500
  static const Color mint = Color(0xFFA7F3D0); // Mint 200
  static const Color forest = Color(0xFF064E3B); // Forest Green 900

  // Neutros y Superficies (Clean & Dark Slate)
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFF1F5F9); // Slate 100

  // Estados de Reporte
  static const Color statusPending = Color(0xFFF59E0B); // Amber 500
  static const Color statusAssigned = Color(0xFF6366F1); // Indigo 500
  static const Color statusInProgress = Color(0xFF3B82F6); // Blue 500
  static const Color statusPaused = Color(0xFF8B5CF6); // Purple 500
  static const Color statusResolved = Color(0xFF10B981); // Emerald 500
  static const Color statusCancelled = Color(0xFF64748B); // Slate 500

  // Niveles de Prioridad
  static const Color priorityLow = Color(0xFF10B981); // Verde
  static const Color priorityMedium = Color(0xFFF59E0B); // Ámbar
  static const Color priorityHigh = Color(0xFFF97316); // Naranja
  static const Color priorityCritical = Color(0xFFEF4444); // Rojo

  // Colores de feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
