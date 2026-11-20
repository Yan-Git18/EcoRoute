import 'package:cloud_firestore/cloud_firestore.dart';

const communityReportsCollection = 'communityReports';

Map<String, dynamic> communityReportDocument(Map<String, dynamic> report) {
  const fields = [
    'reportNumber',
    'categoryId',
    'categoryName',
    'categoryIcon',
    'description',
    'priority',
    'status',
    'latitude',
    'longitude',
    'address',
    'createdAt',
    'updatedAt',
    'imagePaths',
    'imageUrls',
    'evidenceImagePath',
    'evidenceImagePaths',
    'evidenceImageUrl',
    'evidenceImageUrls',
  ];
  return {
    for (final field in fields)
      if (report.containsKey(field)) field: report[field],
  };
}

DocumentReference<Map<String, dynamic>> communityReportRef(
  DocumentReference<Map<String, dynamic>> report,
) => report.firestore.collection(communityReportsCollection).doc(report.id);
