import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../errors/exceptions.dart';

/// Contrato abstracto para servicios de almacenamiento de archivos multimedia.
///
/// Principio DIP (Inversión de Dependencias) y SRP (Responsabilidad Única).
/// Centraliza la subida de archivos binarios a la nube (Firebase Storage).
/// Ubicación: `lib/core/services/firebase_storage_service.dart`
/// Capa: Core (Services)
abstract class StorageService {
  Future<String?> uploadFile({
    required List<int> bytes,
    required String path,
    String contentType = 'image/jpeg',
    Map<String, String>? customMetadata,
  });
}

/// Implementación concreta de [StorageService] utilizando Firebase Storage.
class FirebaseStorageServiceImpl implements StorageService {
  final FirebaseStorage? _customStorage;

  FirebaseStorageServiceImpl({FirebaseStorage? storage})
      : _customStorage = storage;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  @override
  Future<String?> uploadFile({
    required List<int> bytes,
    required String path,
    String contentType = 'image/jpeg',
    Map<String, String>? customMetadata,
  }) async {
    if (!_isFirebaseReady && _customStorage == null) {
      return null;
    }

    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          ...?customMetadata,
        },
      );

      final uploadTask = await ref.putData(
        Uint8List.fromList(bytes),
        metadata,
      );

      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'No se pudo subir el archivo: ${e.message ?? e.code}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(message: 'Error al procesar el archivo en almacenamiento: $e');
    }
  }
}

/// Base abstracta para DataSources que delegan almacenamiento en [StorageService].
abstract class BaseFirebaseStorageDataSource {
  final StorageService storageService;

  BaseFirebaseStorageDataSource({
    StorageService? storageService,
    FirebaseStorage? storage,
  }) : storageService = storageService ?? FirebaseStorageServiceImpl(storage: storage);
}
