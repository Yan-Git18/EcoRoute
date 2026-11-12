import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    test('formatShortDate formatea día mes año en español', () {
      final date = DateTime(2026, 5, 20, 14, 5);
      final formatted = DateFormatter.formatShortDate(date);
      expect(formatted, '20 may. 2026');
    });

    test('formatTimeAgo calcula diferencias relativas correctamente', () {
      final now = DateTime.now();

      expect(DateFormatter.formatTimeAgo(now.subtract(const Duration(minutes: 5))), 'Hace 5 min');
      expect(DateFormatter.formatTimeAgo(now.subtract(const Duration(hours: 3))), 'Hace 3 h');
      expect(DateFormatter.formatTimeAgo(now.subtract(const Duration(days: 2))), 'Hace 2 d');
    });
  });
}
