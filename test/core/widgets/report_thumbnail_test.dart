import 'dart:convert';
import 'package:ecoroute/core/services/firestore_media.dart';
import 'package:ecoroute/core/widgets/media_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/widgets/report_thumbnail.dart';
import 'package:image/image.dart' as image;

void main() {
  testWidgets(
    'ReportThumbnail abre imágenes de Firestore y URLs de datos antiguas',
    (tester) async {
      final png = image.encodePng(image.Image(width: 2, height: 2));
      const path = 'reports/reporte/media/photo_0';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreImageProvider(
              path,
            ).overrideWith((ref) => Stream.value(png)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  ReportThumbnail(imageUrl: FirestoreMedia.location(path)),
                  ReportThumbnail(
                    imageUrl: 'data:image/png;base64,${base64Encode(png)}',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNWidgets(2));
    },
  );

  testWidgets('ReportThumbnail con URL vacía o nula muestra placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReportThumbnail(imageUrl: null, width: 80, height: 80),
        ),
      ),
    );

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('ReportThumbnail con URL de red renderiza Image.network', (
    tester,
  ) async {
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
