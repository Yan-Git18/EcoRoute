import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/report_entity.dart';

/// DTO para serialización y deserialización de reportes ciudadanos en Cloud Firestore.
///
/// Ubicación: `lib/features/citizen/data/models/report_dto.dart`
/// Capa: Data (Models)
class ReportDto {
  final String id;
  final String reportNumber;
  final String citizenId;
  final String citizenName;
  final String? citizenPhone;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String description;
  final String priority;
  final String status;
  final double latitude;
  final double longitude;
  final String address;
  final String? reference;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReportDto({
    required this.id,
    required this.reportNumber,
    required this.citizenId,
    required this.citizenName,
    this.citizenPhone,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.description,
    required this.priority,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.reference,
    required this.imageUrls,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReportDto.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final locationMap = map['location'] as Map<String, dynamic>? ?? {};

    return ReportDto(
      id: documentId,
      reportNumber: map['reportNumber'] as String? ?? '',
      citizenId: map['citizenId'] as String? ?? '',
      citizenName: map['citizenName'] as String? ?? '',
      citizenPhone: map['citizenPhone'] as String?,
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      categoryIcon: map['categoryIcon'] as String? ?? 'warning_amber_rounded',
      description: map['description'] as String? ?? '',
      priority: map['priority'] as String? ?? 'low',
      status: map['status'] as String? ?? 'pending',
      latitude: (locationMap['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (locationMap['longitude'] as num?)?.toDouble() ?? 0.0,
      address: locationMap['address'] as String? ?? '',
      reference: locationMap['reference'] as String?,
      imageUrls: (map['images'] as List<dynamic>?)
              ?.map((e) => e is Map ? (e['url'] as String? ?? '') : e.toString())
              .where((url) => url.isNotEmpty)
              .toList() ??
          [],
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportNumber': reportNumber,
      'citizenId': citizenId,
      'citizenName': citizenName,
      'citizenPhone': citizenPhone,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'description': description,
      'priority': priority,
      'status': status,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'reference': reference,
      },
      'images': imageUrls.map((url) => {'url': url, 'uploadedAt': Timestamp.now()}).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ReportEntity toDomain() {
    return ReportEntity(
      id: id,
      reportNumber: reportNumber,
      citizenId: citizenId,
      citizenName: citizenName,
      citizenPhone: citizenPhone,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      description: description,
      priority: ReportPriority.fromString(priority),
      status: ReportStatus.fromString(status),
      latitude: latitude,
      longitude: longitude,
      address: address,
      reference: reference,
      imageUrls: imageUrls,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ReportDto.fromDomain(ReportEntity entity) {
    return ReportDto(
      id: entity.id,
      reportNumber: entity.reportNumber,
      citizenId: entity.citizenId,
      citizenName: entity.citizenName,
      citizenPhone: entity.citizenPhone,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      categoryIcon: entity.categoryIcon,
      description: entity.description,
      priority: entity.priority.toDbString(),
      status: entity.status.toDbString(),
      latitude: entity.latitude,
      longitude: entity.longitude,
      address: entity.address,
      reference: entity.reference,
      imageUrls: entity.imageUrls,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
