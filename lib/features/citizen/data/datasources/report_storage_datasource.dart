import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/services/firebase_storage_service.dart';

/// Contrato abstracto para la fuente de datos de almacenamiento de archivos multimedia de reportes.
///
/// Principio SRP: Responsabilidad única de gestionar la subida de imágenes de incidencias ciudadanas.
abstract class ReportStorageDataSource {
  Future<String?> uploadReportImage({
    required List<int> imageBytes,
    required String fileName,
  });
}

/// Implementación concreta de [ReportStorageDataSource] delegando en [StorageService].
class FirebaseReportStorageDataSourceImpl implements ReportStorageDataSource {
  final StorageService _storageService;

  FirebaseReportStorageDataSourceImpl({
    StorageService? storageService,
    FirebaseStorage? storage,
  }) : _storageService = storageService ?? FirebaseStorageServiceImpl(storage: storage);

  @override
  Future<String?> uploadReportImage({
    required List<int> imageBytes,
    required String fileName,
  }) {
    return _storageService.uploadFile(
      bytes: imageBytes,
      path: 'reports/$fileName',
    );
  }
}
