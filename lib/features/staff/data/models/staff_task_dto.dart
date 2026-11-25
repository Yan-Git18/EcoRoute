import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../citizen/data/models/report_media_fields.dart';
import '../../../../core/constants/geo_constants.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/staff_task_entity.dart';

/// DTO para la serialización de tareas del Personal en Cloud Firestore.
/// Capa: Data (Models)
class StaffTaskDto {
  static const assignedStatuses = ['assigned', 'asignado'];
  static const openStatuses = [
    ...assignedStatuses,
    'in_progress',
    'en proceso',
  ];
  static const visibleStatuses = [...openStatuses, 'resolved', 'resuelto'];

  final String id;
  final String reportNumber;
  final String? teamId;
  final String? assignedStaffId;
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
  final bool hasReportLocation;
  final List<String> reportImageUrls;
  final String? evidenceImageUrl;
  final List<String> evidenceImageUrls;
  final String? resolutionNotes;
  final DateTime assignedAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const StaffTaskDto({
    required this.id,
    required this.reportNumber,
    this.teamId,
    this.assignedStaffId,
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
    this.hasReportLocation = true,
    required this.reportImageUrls,
    this.evidenceImageUrl,
    this.evidenceImageUrls = const [],
    this.resolutionNotes,
    required this.assignedAt,
    this.updatedAt,
    this.resolvedAt,
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

    final evidence = ReportMediaFields.evidence(map);
    final teamId = map['assignedToTeamId'] as String?;

    return StaffTaskDto(
      id: id,
      reportNumber: map['reportNumber'] as String? ?? '#0000',
      teamId: teamId?.isNotEmpty == true ? teamId : null,
      assignedStaffId: map['assignedStaffId'] as String?,
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
      hasReportLocation: hasValidGeo,
      reportImageUrls: ReportMediaFields.photos(map),
      evidenceImageUrl: evidence.firstOrNull,
      evidenceImageUrls: evidence,
      resolutionNotes: map['resolutionNotes'] as String?,
      assignedAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
      resolvedAt: switch (map['resolvedAt']) {
        Timestamp timestamp => timestamp.toDate(),
        String date => DateTime.tryParse(date),
        _ => null,
      },
    );
  }

  StaffTaskEntity toDomain() {
    return StaffTaskEntity(
      id: id,
      reportNumber: reportNumber,
      teamId: teamId,
      assignedStaffId: assignedStaffId,
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
      hasReportLocation: hasReportLocation,
      reportImageUrls: reportImageUrls,
      evidenceImageUrl: evidenceImageUrl,
      evidenceImageUrls: evidenceImageUrls,
      resolutionNotes: resolutionNotes,
      assignedAt: assignedAt,
      updatedAt: updatedAt,
      resolvedAt: resolvedAt,
    );
  }
}
