import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/services/firebase_storage_service.dart';
import 'package:ecoroute/features/citizen/data/datasources/report_storage_datasource.dart';
import 'package:ecoroute/features/staff/data/datasources/staff_storage_datasource.dart';

class MockStorageService implements StorageService {
  String? returnUrl = 'https://storage.googleapis.com/test-bucket/test.jpg';
  List<int>? lastBytes;
  String? lastPath;

  @override
  Future<String?> uploadFile({
    required List<int> bytes,
    required String path,
    String contentType = 'image/jpeg',
    Map<String, String>? customMetadata,
  }) async {
    lastBytes = bytes;
    lastPath = path;
    return returnUrl;
  }
}

void main() {
  group('StorageService & DataSources', () {
    test('FirebaseReportStorageDataSourceImpl delega subida a reports/fileName', () async {
      final mock = MockStorageService();
      final ds = FirebaseReportStorageDataSourceImpl(storageService: mock);

      final url = await ds.uploadReportImage(
        imageBytes: [1, 2, 3],
        fileName: 'report-123.jpg',
      );

      expect(url, 'https://storage.googleapis.com/test-bucket/test.jpg');
      expect(mock.lastPath, 'reports/report-123.jpg');
      expect(mock.lastBytes, [1, 2, 3]);
    });

    test('FirebaseStaffStorageDataSourceImpl delega subida a evidence/fileName', () async {
      final mock = MockStorageService();
      final ds = FirebaseStaffStorageDataSourceImpl(storageService: mock);

      final url = await ds.uploadEvidenceImage(
        imageBytes: [4, 5, 6],
        fileName: 'evidence-456.jpg',
      );

      expect(url, 'https://storage.googleapis.com/test-bucket/test.jpg');
      expect(mock.lastPath, 'evidence/evidence-456.jpg');
      expect(mock.lastBytes, [4, 5, 6]);
    });

    test('FirebaseStorageServiceImpl retorna null cuando Firebase no está inicializado en tests', () async {
      final service = FirebaseStorageServiceImpl();
      final url = await service.uploadFile(
        bytes: [1, 2, 3],
        path: 'test.jpg',
      );
      expect(url, isNull);
    });
  });
}

