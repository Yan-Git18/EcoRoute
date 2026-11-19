import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firestore_media.dart';
import '../../domain/entities/report_entity.dart';
import 'report_media_fields.dart';

/// DTO para serialización de eventos de auditoría de un reporte en Firestore (`reports/{id}/history`).
class ReportHistoryItemDto {
  final String previousStatus;
  final String newStatus;
  final String? changedByUserId;
  final String? changedByUserName;
  final String? changedByUserRole;
  final String? comment;
  final DateTime timestamp;

  const ReportHistoryItemDto({
    required this.previousStatus,
    required this.newStatus,
    this.changedByUserId,
    this.changedByUserName,
    this.changedByUserRole,
    this.comment,
    required this.timestamp,
  });

  factory ReportHistoryItemDto.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ReportHistoryItemDto(
      previousStatus: map['previousStatus'] as String? ?? 'none',
      newStatus: map['newStatus'] as String? ?? 'pending',
      changedByUserId: map['changedByUserId'] as String?,
      changedByUserName: map['changedByUserName'] as String?,
      changedByUserRole: map['changedByUserRole'] as String?,
      comment: map['comment'] as String?,
      timestamp: parseDate(map['timestamp']),
    );
  }

  ReportHistoryItem toDomain() {
    return ReportHistoryItem(
      previousStatus: previousStatus,
      newStatus: newStatus,
      changedByUserId: changedByUserId,
      changedByUserName: changedByUserName,
      changedByUserRole: changedByUserRole,
      comment: comment,
      timestamp: timestamp,
    );
  }

  factory ReportHistoryItemDto.fromDomain(ReportHistoryItem item) {
    return ReportHistoryItemDto(
      previousStatus: item.previousStatus,
      newStatus: item.newStatus,
      changedByUserId: item.changedByUserId,
      changedByUserName: item.changedByUserName,
      changedByUserRole: item.changedByUserRole,
      comment: item.comment,
      timestamp: item.timestamp,
    );
  }
}

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
  final String? assignedToTeamId;
  final String? assignedToTeamName;
  final String? assignedStaffName;
  final String? assignedVehicle;
  final String? evidenceImageUrl;
  final List<String> evidenceImageUrls;
  final String? resolutionNotes;
  final List<ReportHistoryItemDto> history;

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
    this.assignedToTeamId,
    this.assignedToTeamName,
    this.assignedStaffName,
    this.assignedVehicle,
    this.evidenceImageUrl,
    this.evidenceImageUrls = const [],
    this.resolutionNotes,
    this.history = const [],
  });

  factory ReportDto.fromMap(
    Map<String, dynamic> map,
    String documentId, {
    List<ReportHistoryItemDto> history = const [],
  }) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final locationMap = map['location'] as Map<String, dynamic>? ?? {};
    final rawLat = (locationMap['latitude'] as num?)?.toDouble() ??
        (map['latitude'] as num?)?.toDouble() ??
        0.0;
    final rawLng = (locationMap['longitude'] as num?)?.toDouble() ??
        (map['longitude'] as num?)?.toDouble() ??
        0.0;
    final rawAddr = (locationMap['address'] as String?) ??
        (map['address'] as String?) ??
        '';
    final rawRef = (locationMap['reference'] as String?) ??
        (map['reference'] as String?);

    final evidence = ReportMediaFields.evidence(map);

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
      latitude: rawLat,
      longitude: rawLng,
      address: rawAddr,
      reference: rawRef,
      imageUrls: ReportMediaFields.photos(map),
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
      assignedToTeamId: map['assignedToTeamId'] as String?,
      assignedToTeamName: map['assignedToTeamName'] as String?,
      assignedStaffName: map['assignedStaffName'] as String? ?? (map['assignedToTeamName'] as String?),
      assignedVehicle: map['assignedVehicle'] as String?,
      evidenceImageUrl: evidence.firstOrNull,
      evidenceImageUrls: evidence,
      resolutionNotes: map['resolutionNotes'] as String? ?? (map['resolutionComment'] as String?),
      history: history,
    );
  }

  Map<String, dynamic> toMap() {
    final paths = imageUrls.map(FirestoreMedia.path).whereType<String>().toList();
    final legacyUrls = imageUrls.where((url) => FirestoreMedia.path(url) == null).toList();
    final evidence = evidenceImageUrls.isNotEmpty
        ? evidenceImageUrls
        : [if (evidenceImageUrl case final location?) location];
    final evidencePaths = evidence.map(FirestoreMedia.path).whereType<String>().toList();
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
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      if (reference != null) 'reference': reference,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'reference': reference,
      },
      if (paths.isNotEmpty) 'imagePaths': paths,
      if (legacyUrls.isNotEmpty) 'imageUrls': legacyUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      if (assignedToTeamId != null) 'assignedToTeamId': assignedToTeamId,
      if (assignedToTeamName != null) 'assignedToTeamName': assignedToTeamName,
      if (assignedStaffName != null) 'assignedStaffName': assignedStaffName,
      if (assignedVehicle != null) 'assignedVehicle': assignedVehicle,
      if (evidencePaths.isNotEmpty) 'evidenceImagePath': evidencePaths.first,
      if (evidencePaths.length > 1) 'evidenceImagePaths': evidencePaths,
      if (evidencePaths.isEmpty && evidence.isNotEmpty) 'evidenceImageUrl': evidence.first,
      if (evidencePaths.isEmpty && evidence.length > 1) 'evidenceImageUrls': evidence,
      if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
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
      assignedToTeamId: assignedToTeamId,
      assignedToTeamName: assignedToTeamName,
      assignedStaffName: assignedStaffName,
      assignedVehicle: assignedVehicle,
      evidenceImageUrl: evidenceImageUrl,
      evidenceImageUrls: evidenceImageUrls,
      resolutionNotes: resolutionNotes,
      history: history.map((h) => h.toDomain()).toList(),
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
      assignedToTeamId: entity.assignedToTeamId,
      assignedToTeamName: entity.assignedToTeamName,
      assignedStaffName: entity.assignedStaffName,
      assignedVehicle: entity.assignedVehicle,
      evidenceImageUrl: entity.evidenceImageUrl,
      evidenceImageUrls: entity.evidenceImageUrls,
      resolutionNotes: entity.resolutionNotes,
      history: entity.history.map(ReportHistoryItemDto.fromDomain).toList(),
    );
  }
}
