import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/widgets/report_thumbnail.dart';

void main() {
  testWidgets('ReportThumbnail con URL vacía o nula muestra placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReportThumbnail(
            imageUrl: null,
            width: 80,
            height: 80,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('ReportThumbnail con URL de red renderiza Image.network', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReportThumbnail(
            imageUrl: 'https://example.com/test.jpg',
            width: 80,
            height: 80,
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
  });
}

