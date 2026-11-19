import '../../../citizen/domain/entities/report_entity.dart';

/// Entidad inmutable de Tarea de Limpieza asignada al Personal de Campo.
///
/// Principio SRP: Representa exclusivamente los datos de negocio de una tarea operativa.
///
/// Ubicación: `lib/features/staff/domain/entities/staff_task_entity.dart`
/// Capa: Domain (Entities)
class StaffTaskEntity {
  final String id;
  final String reportNumber;
  final String citizenId;
  final String citizenName;
  final String? citizenPhone;
  final String categoryName;
  final String categoryIcon;
  final String description;
  final ReportPriority priority;
  final ReportStatus status;
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

  const StaffTaskEntity({
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

  bool get isPending => status == ReportStatus.pending || status == ReportStatus.assigned;
  bool get isInProgress => status == ReportStatus.inProgress;
  bool get isResolved => status == ReportStatus.resolved;

  List<String> get allEvidenceImageUrls => evidenceImageUrls.isNotEmpty
      ? evidenceImageUrls
      : (evidenceImageUrl != null && evidenceImageUrl!.isNotEmpty ? [evidenceImageUrl!] : const []);

  StaffTaskEntity copyWith({
    String? id,
    String? reportNumber,
    String? citizenId,
    String? citizenName,
    String? citizenPhone,
    String? categoryName,
    String? categoryIcon,
    String? description,
    ReportPriority? priority,
    ReportStatus? status,
    String? address,
    String? reference,
    double? latitude,
    double? longitude,
    List<String>? reportImageUrls,
    String? evidenceImageUrl,
    List<String>? evidenceImageUrls,
    String? resolutionNotes,
    DateTime? assignedAt,
    DateTime? updatedAt,
  }) {
    final nextEvidenceUrls = evidenceImageUrls ?? this.evidenceImageUrls;
    final firstEvidence = evidenceImageUrl ??
        (nextEvidenceUrls.isNotEmpty ? nextEvidenceUrls.first : this.evidenceImageUrl);

    return StaffTaskEntity(
      id: id ?? this.id,
      reportNumber: reportNumber ?? this.reportNumber,
      citizenId: citizenId ?? this.citizenId,
      citizenName: citizenName ?? this.citizenName,
      citizenPhone: citizenPhone ?? this.citizenPhone,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      address: address ?? this.address,
      reference: reference ?? this.reference,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      reportImageUrls: reportImageUrls ?? this.reportImageUrls,
      evidenceImageUrl: firstEvidence,
      evidenceImageUrls: nextEvidenceUrls,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      assignedAt: assignedAt ?? this.assignedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
