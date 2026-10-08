import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/errors/exceptions.dart';

/// Contrato abstracto para el almacenamiento de fotografías de evidencia de limpieza.
///
/// Principio SRP: Responsabilidad única de subir fotos de resolución a Firebase Storage.
abstract class StaffStorageDataSource {
  Future<String?> uploadEvidenceImage({
    required List<int> imageBytes,
    required String fileName,
  });
}

/// Implementación concreta de StaffStorageDataSource con Firebase Storage.
class FirebaseStaffStorageDataSourceImpl implements StaffStorageDataSource {
  final FirebaseStorage? _customStorage;

  FirebaseStaffStorageDataSourceImpl({FirebaseStorage? storage})
      : _customStorage = storage;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  @override
  Future<String?> uploadEvidenceImage({
    required List<int> imageBytes,
    required String fileName,
  }) async {
    if (!_isFirebaseReady && _customStorage == null) {
      return null;
    }

    try {
      final ref = _storage.ref().child('evidence/$fileName');
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
        message: 'No se pudo subir la foto de evidencia de atención: ${e.message ?? e.code}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(message: 'Error al procesar la imagen de evidencia: $e');
    }
  }
}
