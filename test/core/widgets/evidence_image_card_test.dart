import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/widgets/evidence_image_card.dart';

void main() {
  testWidgets('EvidenceImageCard renderiza imagen, badge de atención y botón Ampliar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EvidenceImageCard(
            imageUrl: 'https://images.unsplash.com/photo-cleaned.jpg',
            badgeLabel: 'Zona atendida',
            reportTitle: 'Evidencia #100',
          ),
        ),
      ),
    );

    expect(find.text('Zona atendida'), findsOneWidget);
    expect(find.text('Ampliar'), findsOneWidget);
    expect(find.byIcon(Icons.zoom_in_rounded), findsOneWidget);

    // Tocar botón Ampliar
    await tester.tap(find.text('Ampliar'));
    await tester.pumpAndSettle();

    expect(find.text('Evidencia #100'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}

