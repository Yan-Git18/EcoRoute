import '../../../../core/services/firebase_storage_service.dart';

/// Contrato abstracto para la fuente de datos de almacenamiento de archivos multimedia de reportes.
abstract class ReportStorageDataSource {
  Future<String?> uploadReportImage({
    required List<int> imageBytes,
    required String fileName,
  });
}

/// Implementación concreta de [ReportStorageDataSource] delegando en [StorageService].
class FirebaseReportStorageDataSourceImpl extends BaseFirebaseStorageDataSource
    implements ReportStorageDataSource {
  FirebaseReportStorageDataSourceImpl({super.storageService, super.storage});

  @override
  Future<String?> uploadReportImage({
    required List<int> imageBytes,
    required String fileName,
  }) {
    return storageService.uploadFile(
      bytes: imageBytes,
      path: 'reports/$fileName',
    );
  }
}
