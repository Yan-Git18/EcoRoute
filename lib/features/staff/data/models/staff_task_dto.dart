import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/geo_constants.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/staff_task_entity.dart';

/// DTO para la serialización de tareas del Personal en Cloud Firestore.
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
  final String? reference;
  final double latitude;
  final double longitude;
  final List<String> reportImageUrls;
  final String? evidenceImageUrl;
  final List<String> evidenceImageUrls;
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
    this.reference,
    required this.latitude,
    required this.longitude,
    required this.reportImageUrls,
    this.evidenceImageUrl,
    this.evidenceImageUrls = const [],
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

    final locationMap = map['location'] as Map<String, dynamic>? ?? {};

    final rawLat = (map['latitude'] as num?)?.toDouble() ??
        (locationMap['latitude'] as num?)?.toDouble() ??
        0.0;
    final rawLng = (map['longitude'] as num?)?.toDouble() ??
        (locationMap['longitude'] as num?)?.toDouble() ??
        0.0;
    final hasValidGeo = rawLat != 0.0 &&
        rawLng != 0.0 &&
        AppGeoConstants.isInsideCajamarca(rawLat, rawLng);

    final rawAddress = (map['address'] as String?) ?? (locationMap['address'] as String?);
    final resolvedAddress = (rawAddress != null && rawAddress.trim().isNotEmpty && rawAddress != 'Ubicación registrada')
        ? rawAddress.trim()
        : AppGeoConstants.defaultAddress;

    final resolvedReference = (map['reference'] as String?) ?? (locationMap['reference'] as String?);

    // Extraer imágenes ciudadanas de 'images' y/o 'imageUrls'
    final List<String> extractedCitizenImages = [];
    if (map['images'] is List) {
      for (final item in map['images']) {
        if (item is Map && item['url'] != null) {
          extractedCitizenImages.add(item['url'].toString());
        } else if (item is String && item.isNotEmpty) {
          extractedCitizenImages.add(item);
        }
      }
    }
    if (map['imageUrls'] is List) {
      for (final item in map['imageUrls']) {
        if (item is String && item.isNotEmpty && !extractedCitizenImages.contains(item)) {
          extractedCitizenImages.add(item);
        }
      }
    }

    // Extraer imágenes de evidencia de limpieza
    final List<String> extractedEvidence = [];
    if (map['evidenceImageUrls'] is List) {
      for (final item in map['evidenceImageUrls']) {
        if (item != null && item.toString().isNotEmpty) {
          extractedEvidence.add(item.toString());
        }
      }
    }
    final singleEvidence = map['evidenceImageUrl'] as String? ?? (map['evidencePhoto'] as String?);
    if (extractedEvidence.isEmpty && singleEvidence != null && singleEvidence.isNotEmpty) {
      extractedEvidence.add(singleEvidence);
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
      address: resolvedAddress,
      reference: resolvedReference,
      latitude: hasValidGeo ? rawLat : AppGeoConstants.cajamarcaCenterLat,
      longitude: hasValidGeo ? rawLng : AppGeoConstants.cajamarcaCenterLng,
      reportImageUrls: extractedCitizenImages,
      evidenceImageUrl: singleEvidence ?? (extractedEvidence.isNotEmpty ? extractedEvidence.first : null),
      evidenceImageUrls: extractedEvidence,
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
      reference: reference,
      latitude: latitude,
      longitude: longitude,
      reportImageUrls: reportImageUrls,
      evidenceImageUrl: evidenceImageUrl,
      evidenceImageUrls: evidenceImageUrls,
      resolutionNotes: resolutionNotes,
      assignedAt: assignedAt,
      updatedAt: updatedAt,
    );
  }
}
