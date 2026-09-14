import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/citizen/presentation/views/report_detail_screen.dart';

void main() {
  testWidgets('Renderiza ReportDetailScreen con todos los datos y la línea de tiempo de auditoría', (WidgetTester tester) async {
    final testReport = ReportEntity(
      id: 'rep-001',
      reportNumber: '#0012',
      citizenId: 'user-1',
      citizenName: 'Juan Pérez',
      categoryId: 'waste_accumulation',
      categoryName: 'Acumulación de basura',
      categoryIcon: 'delete_outline_rounded',
      description: 'Hay bolsas de basura acumuladas desde hace varios días.',
      priority: ReportPriority.high,
      status: ReportStatus.inProgress,
      latitude: -12.046,
      longitude: -77.042,
      address: 'Av. Los Incas, Cajamarca',
      imageUrls: const [],
      createdAt: DateTime(2025, 9, 12, 10, 24),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ReportDetailScreen(
            reportId: testReport.id,
            initialReport: testReport,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verificamos encabezado
    expect(find.text('Detalle del reporte'), findsOneWidget);

    // 2. Verificamos número y categoría
    expect(find.text('#0012'), findsOneWidget);
    expect(find.text('Acumulación de basura'), findsOneWidget);
    expect(find.text('Av. Los Incas, Cajamarca'), findsOneWidget);

    // 3. Verificamos descripción
    expect(find.text('Hay bolsas de basura acumuladas desde hace varios días.'), findsOneWidget);

    // 4. Verificamos prioridad
    expect(find.text('Alta'), findsOneWidget);

    // 5. Verificamos que contenga la sección de historial de estados
    expect(find.text('Historial de estados'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('Reporte creado')),
      findsOneWidget,
    );
  });
}
