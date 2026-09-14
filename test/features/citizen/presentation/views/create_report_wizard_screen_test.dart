import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/features/citizen/presentation/views/create_report_wizard_screen.dart';

void main() {
  testWidgets('Renderiza CreateReportWizardScreen en Paso 1 y avanza al Paso 2 al seleccionar categoría', (WidgetTester tester) async {
    // Configurar un tamaño de pantalla realista para dispositivos móviles
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CreateReportWizardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verificamos elementos del Paso 1
    expect(find.text('Crear reporte'), findsOneWidget);
    expect(find.text('¿Qué problema encontraste?'), findsOneWidget);
    expect(find.text('Acumulación de basura'), findsOneWidget);
    expect(find.text('Contenedor lleno'), findsOneWidget);
    expect(find.text('Residuos en vía pública'), findsOneWidget);

    // 2. Seleccionamos la categoría 'Acumulación de basura'
    await tester.tap(find.text('Acumulación de basura'));
    await tester.pumpAndSettle();

    // 3. Pulsamos en 'Siguiente'
    expect(find.text('Siguiente'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    // 4. Verificamos que avanzó al Paso 2 (Fotografía)
    expect(find.text('Agrega una fotografía'), findsOneWidget);
    expect(find.text('Tomar foto'), findsOneWidget);
    expect(find.text('Elegir de la galería'), findsOneWidget);
  });
}
