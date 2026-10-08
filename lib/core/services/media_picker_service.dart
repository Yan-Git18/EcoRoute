import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Resultado encuadronado de selección de medios (imagen).
class MediaPickResult {
  final XFile? file;
  final Uint8List? bytes;
  final String? errorMessage;

  const MediaPickResult({
    this.file,
    this.bytes,
    this.errorMessage,
  });

  bool get hasImage => file != null && bytes != null && bytes!.isNotEmpty;
}

/// Contrato del servicio de selección y captura de imágenes.
///
/// Responsabilidad Única: Encapsular el acceso a cámara y galería de imágenes.
abstract class MediaPickerService {
  Future<MediaPickResult> pickImageFromCamera({int quality = 80, double maxWidth = 1200});
  Future<MediaPickResult> pickImageFromGallery({int quality = 80, double maxWidth = 1200});
}

/// Implementación concreta de MediaPickerService con ImagePicker.
class ImagePickerMediaServiceImpl implements MediaPickerService {
  final ImagePicker _picker;

  ImagePickerMediaServiceImpl({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<MediaPickResult> pickImageFromCamera({int quality = 80, double maxWidth = 1200}) async {
    return _pickImage(ImageSource.camera, quality: quality, maxWidth: maxWidth);
  }

  @override
  Future<MediaPickResult> pickImageFromGallery({int quality = 80, double maxWidth = 1200}) async {
    return _pickImage(ImageSource.gallery, quality: quality, maxWidth: maxWidth);
  }

  Future<MediaPickResult> _pickImage(
    ImageSource source, {
    required int quality,
    required double maxWidth,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: quality,
        maxWidth: maxWidth,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        return MediaPickResult(file: picked, bytes: bytes);
      }
      return const MediaPickResult();
    } catch (e) {
      return MediaPickResult(
        errorMessage: 'No se pudo acceder a la imagen seleccionada: $e',
      );
    }
  }
}

/// Provider de Riverpod para MediaPickerService
final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  return ImagePickerMediaServiceImpl();
});
