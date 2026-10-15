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

  testWidgets('Renderiza ReportDetailScreen con los elementos exactos del diseño mockup', (WidgetTester tester) async {
    final mockupReport = ReportEntity(
      id: 'rep-mockup',
      reportNumber: '920049',
      citizenId: 'user-mockup',
      citizenName: 'Hernán',
      categoryId: 'waste_accumulation',
      categoryName: 'Acumulación de basura',
      categoryIcon: 'delete_outline_rounded',
      description: 'Acumulación considerable de residuos sólidos en la vía pública obstaculizando el paso.',
      priority: ReportPriority.medium,
      status: ReportStatus.pending,
      latitude: -12.046,
      longitude: -77.042,
      address: 'Rafael Narvaez 278',
      reference: 'hgfghfhgfjfgjfhgh',
      imageUrls: const [],
      createdAt: DateTime(2026, 10, 15, 3, 9),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ReportDetailScreen(
            reportId: mockupReport.id,
            initialReport: mockupReport,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Tarjeta de fotografía vacía
    expect(find.text('Sin fotografía adjunta'), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);

    // 2. Tarjeta resumen: ID con prefijo '#', badge, categoría, dirección y referencia
    expect(find.text('#920049'), findsOneWidget);
    expect(find.text('En revisión'), findsWidgets); // En badge y en tarjeta de detalles
    expect(find.text('Acumulación de basura'), findsOneWidget);
    expect(find.text('Rafael Narvaez 278'), findsOneWidget);
    expect(find.text('Ref: hgfghfhgfjfgjfhgh'), findsOneWidget);

    // 3. Tarjeta de detalles: Descripción y Fecha de reporte
    expect(find.text('Descripción'), findsOneWidget);
    expect(find.text(mockupReport.description), findsOneWidget);
    expect(find.text('Fecha de reporte'), findsOneWidget);
    expect(find.text('15 oct. 2026 - 3:09 a. m.'), findsWidgets);

    // 4. Métricas en 2 columnas: Prioridad "Media" y Estado "En revisión"
    expect(find.text('Prioridad'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);

    // 5. Historial de estados (Timeline)
    expect(find.text('Historial de estados'), findsOneWidget);
    expect(find.text('15 oct. 2026 - 3:54 a. m.'), findsOneWidget);
    expect(find.text('15 oct. 2026 - 5:09 a. m.'), findsOneWidget);
  });
}
