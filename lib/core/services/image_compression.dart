import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;

enum PhotoSize {
  report(1200, 256 * 1024),
  avatar(384, 96 * 1024);

  const PhotoSize(this.longestEdge, this.maxBytes);

  final int longestEdge;
  final int maxBytes;
}

class PhotoCompressionException implements Exception {
  const PhotoCompressionException();

  String get message => 'Elige una imagen válida que se pueda comprimir.';
}

Future<Uint8List> compressPhoto(List<int> bytes, PhotoSize size) {
  return compute(_encodePhoto, (Uint8List.fromList(bytes), size));
}

Uint8List _encodePhoto((Uint8List, PhotoSize) input) {
  final (bytes, size) = input;
  final decoded = image.decodeImage(bytes);
  if (decoded == null) throw const PhotoCompressionException();

  final original = image.bakeOrientation(decoded);
  original.exif.clear();
  final landscape = original.width >= original.height;
  final longestEdge = landscape ? original.width : original.height;

  for (final (scale, quality) in [
    (1.0, 83),
    (1.0, 69),
    (0.75, 74),
    (0.5, 65),
  ]) {
    final edge = (size.longestEdge * scale).round();
    final frame = longestEdge <= edge
        ? original
        : image.copyResize(
            original,
            width: landscape ? edge : null,
            height: landscape ? null : edge,
            interpolation: image.Interpolation.average,
          );
    final encoded = image.encodeJpg(frame, quality: quality);
    if (encoded.length <= size.maxBytes) return encoded;
  }
  throw const PhotoCompressionException();
}
