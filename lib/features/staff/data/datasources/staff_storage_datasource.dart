import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/services/firebase_storage_service.dart';

/// Contrato abstracto para el almacenamiento de fotografías de evidencia de atención.
///
/// Principio SRP: Responsabilidad única de subir fotos de resolución del personal.
abstract class StaffStorageDataSource {
  Future<String?> uploadEvidenceImage({
    required List<int> imageBytes,
    required String fileName,
  });
}

/// Implementación concreta de [StaffStorageDataSource] delegando en [StorageService].
class FirebaseStaffStorageDataSourceImpl implements StaffStorageDataSource {
  final StorageService _storageService;

  FirebaseStaffStorageDataSourceImpl({
    StorageService? storageService,
    FirebaseStorage? storage,
  }) : _storageService = storageService ?? FirebaseStorageServiceImpl(storage: storage);

  @override
  Future<String?> uploadEvidenceImage({
    required List<int> imageBytes,
    required String fileName,
  }) {
    return _storageService.uploadFile(
      bytes: imageBytes,
      path: 'evidence/$fileName',
    );
  }
}
