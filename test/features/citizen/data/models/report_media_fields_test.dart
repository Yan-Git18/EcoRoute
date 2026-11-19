import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/services/firestore_media.dart';
import 'package:ecoroute/features/citizen/data/models/report_dto.dart';
import 'package:ecoroute/features/staff/data/models/staff_task_dto.dart';

void main() {
  test('Reportes y tareas leen fotos antiguas en Base64 sin repetirlas', () {
    const base64Photo = 'data:image/jpeg;base64,abc=';
    final fields = {
      'imageUrls': [base64Photo],
      'images': [
        {'url': base64Photo},
      ],
      'evidenceImageUrls': [base64Photo],
    };
    final report = ReportDto.fromMap(fields, 'example');
    final task = StaffTaskDto.fromFirestore('example', fields);
    expect(report.imageUrls, [base64Photo]);
    expect(report.evidenceImageUrl, base64Photo);
    expect(task.reportImageUrls, report.imageUrls);
    expect(task.evidenceImageUrl, report.evidenceImageUrl);
  });

  test('Un reporte nuevo serializa rutas en lugar de duplicar fotos', () {
    const photo = 'reports/example/media/photo_0';
    const evidence = 'reports/example/media/evidence';
    final dto = ReportDto.fromMap({
      'imagePaths': [photo],
      'evidenceImagePath': evidence,
      'evidenceImageUrl': 'data:image/jpeg;base64,abc=',
    }, 'example');
    expect(dto.imageUrls, [FirestoreMedia.location(photo)]);
    expect(dto.evidenceImageUrl, FirestoreMedia.location(evidence));
    final fields = dto.toMap();
    expect(fields['imagePaths'], [photo]);
    expect(fields['evidenceImagePath'], evidence);
    expect(fields.containsKey('images'), isFalse);
    expect(fields.containsKey('imageUrls'), isFalse);
    expect(fields.containsKey('evidenceImageUrl'), isFalse);
  });
}
