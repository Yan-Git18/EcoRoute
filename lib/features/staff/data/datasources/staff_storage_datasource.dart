import '../../../../core/services/firebase_storage_service.dart';

/// Contrato abstracto para el almacenamiento de fotografías de evidencia de atención.
abstract class StaffStorageDataSource {
  Future<String?> uploadEvidenceImage({
    required List<int> imageBytes,
    required String fileName,
  });
}

/// Implementación concreta de [StaffStorageDataSource] delegando en [StorageService].
class FirebaseStaffStorageDataSourceImpl extends BaseFirebaseStorageDataSource
    implements StaffStorageDataSource {
  FirebaseStaffStorageDataSourceImpl({super.storageService, super.storage});

  @override
  Future<String?> uploadEvidenceImage({
    required List<int> imageBytes,
    required String fileName,
  }) {
    return storageService.uploadFile(
      bytes: imageBytes,
      path: 'evidence/$fileName',
    );
  }
}
