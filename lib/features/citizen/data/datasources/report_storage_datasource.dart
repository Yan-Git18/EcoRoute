import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/errors/exceptions.dart';

/// Contrato abstracto para la fuente de datos de almacenamiento de archivos multimedia.
///
/// Principio SRP: Responsabilidad única de subir y gestionar archivos multimedia en Storage.
abstract class ReportStorageDataSource {
  Future<String?> uploadReportImage({
    required List<int> imageBytes,
    required String fileName,
  });
}

/// Implementación concreta de ReportStorageDataSource con Firebase Storage.
class FirebaseReportStorageDataSourceImpl implements ReportStorageDataSource {
  final FirebaseStorage? _customStorage;

  FirebaseReportStorageDataSourceImpl({FirebaseStorage? storage})
      : _customStorage = storage;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  @override
  Future<String?> uploadReportImage({
    required List<int> imageBytes,
    required String fileName,
  }) async {
    if (!_isFirebaseReady && _customStorage == null) {
      return null;
    }

    try {
      final ref = _storage.ref().child('reports/$fileName');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
      );

      final uploadTask = await ref.putData(
        Uint8List.fromList(imageBytes),
        metadata,
      );

      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'No se pudo subir la fotografía de evidencia: ${e.message ?? e.code}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(message: 'Error al procesar la imagen: $e');
    }
  }
}
