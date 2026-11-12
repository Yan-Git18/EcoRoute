/// Utilidad centralizada para formato de fechas y tiempos relativos en español.
///
/// Principio DRY: Evita la duplicación de formateadores de fechas en tarjetas y vistas.
/// Ubicación: `lib/core/utils/date_formatter.dart`
/// Capa: Core (Utils)
abstract final class DateFormatter {
  static const List<String> _spanishShortMonths = [
    'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
    'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'
  ];

  /// Formatea una fecha en formato corto: "12 nov. 2026".
  static String formatShortDate(DateTime date) {
    final monthName = _spanishShortMonths[date.month - 1];
    return '${date.day} $monthName ${date.year}';
  }

  /// Formatea una fecha relativa: "Hace 5 min", "Hace 2 h", "Hace 3 d".
  static String formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes.clamp(1, 60)} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    } else {
      return 'Hace ${diff.inDays} d';
    }
  }
}

