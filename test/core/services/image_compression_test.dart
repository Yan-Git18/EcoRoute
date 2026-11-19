import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:ecoroute/core/services/image_compression.dart';

void main() {
  test(
    'El avatar se convierte a JPEG dentro del límite de Firestore',
    () async {
      final original = image.encodePng(image.Image(width: 700, height: 1000));
      final compressed = await compressPhoto(original, PhotoSize.avatar);
      final decoded = image.decodeJpg(compressed)!;
      expect(decoded.height, PhotoSize.avatar.longestEdge);
      expect(decoded.width, lessThan(decoded.height));
      expect(compressed.length, lessThanOrEqualTo(PhotoSize.avatar.maxBytes));
    },
  );

  test('La compresión rechaza archivos que no son imágenes', () async {
    await expectLater(
      compressPhoto([0, 1, 2], PhotoSize.report),
      throwsA(isA<PhotoCompressionException>()),
    );
  });
}
