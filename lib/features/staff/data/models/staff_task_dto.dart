import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/staff_task_entity.dart';

/// DTO para la serialización de tareas del Personal en Cloud Firestore.
///
/// Ubicación: `lib/features/staff/data/models/staff_task_dto.dart`
/// Capa: Data (Models)
class StaffTaskDto {
  final String id;
  final String reportNumber;
  final String citizenId;
  final String citizenName;
  final String? citizenPhone;
  final String categoryName;
  final String categoryIcon;
  final String description;
  final String priority;
  final String status;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> reportImageUrls;
  final String? evidenceImageUrl;
  final String? resolutionNotes;
  final DateTime assignedAt;
  final DateTime? updatedAt;

  const StaffTaskDto({
    required this.id,
    required this.reportNumber,
    required this.citizenId,
    required this.citizenName,
    this.citizenPhone,
    required this.categoryName,
    required this.categoryIcon,
    required this.description,
    required this.priority,
    required this.status,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.reportImageUrls,
    this.evidenceImageUrl,
    this.resolutionNotes,
    required this.assignedAt,
    this.updatedAt,
  });

  factory StaffTaskDto.fromFirestore(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return StaffTaskDto(
      id: id,
      reportNumber: map['reportNumber'] as String? ?? '#0000',
      citizenId: map['citizenId'] as String? ?? '',
      citizenName: map['citizenName'] as String? ?? 'Ciudadano',
      citizenPhone: map['citizenPhone'] as String?,
      categoryName: map['categoryName'] as String? ?? 'Incidencia Ambiental',
      categoryIcon: map['categoryIcon'] as String? ?? 'cleaning_services_rounded',
      description: map['description'] as String? ?? '',
      priority: map['priority'] as String? ?? 'medium',
      status: map['status'] as String? ?? 'assigned',
      address: map['address'] as String? ?? 'Ubicación registrada',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      reportImageUrls: (map['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      evidenceImageUrl: map['evidenceImageUrl'] as String?,
      resolutionNotes: map['resolutionNotes'] as String?,
      assignedAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  StaffTaskEntity toDomain() {
    return StaffTaskEntity(
      id: id,
      reportNumber: reportNumber,
      citizenId: citizenId,
      citizenName: citizenName,
      citizenPhone: citizenPhone,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      description: description,
      priority: ReportPriority.fromString(priority),
      status: ReportStatus.fromString(status),
      address: address,
      latitude: latitude,
      longitude: longitude,
      reportImageUrls: reportImageUrls,
      evidenceImageUrl: evidenceImageUrl,
      resolutionNotes: resolutionNotes,
      assignedAt: assignedAt,
      updatedAt: updatedAt,
    );
  }
}
