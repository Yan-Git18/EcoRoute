/// Prioridad de atención para un reporte de residuos.
enum ReportPriority {
  low('Baja'),
  medium('Media'),
  high('Alta');

  final String label;
  const ReportPriority(this.label);

  static ReportPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'high':
      case 'alta':
        return ReportPriority.high;
      case 'medium':
      case 'media':
        return ReportPriority.medium;
      case 'low':
      case 'baja':
      default:
        return ReportPriority.low;
    }
  }

  String toDbString() {
    switch (this) {
      case ReportPriority.high:
        return 'high';
      case ReportPriority.medium:
        return 'medium';
      case ReportPriority.low:
        return 'low';
    }
  }
}

/// Estado actual del ciclo de vida del reporte.
enum ReportStatus {
  pending('Pendiente'),
  assigned('Asignado'),
  inProgress('En Proceso'),
  resolved('Resuelto'),
  cancelled('Cancelado');

  final String label;
  const ReportStatus(this.label);

  static ReportStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'assigned':
      case 'asignado':
        return ReportStatus.assigned;
      case 'in_progress':
      case 'in行為':
      case 'en proceso':
        return ReportStatus.inProgress;
      case 'resolved':
      case 'resuelto':
        return ReportStatus.resolved;
      case 'cancelled':
      case 'cancelado':
        return ReportStatus.cancelled;
      case 'pending':
      case 'pendiente':
      default:
        return ReportStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.assigned:
        return 'assigned';
      case ReportStatus.inProgress:
        return 'in_progress';
      case ReportStatus.resolved:
        return 'resolved';
      case ReportStatus.cancelled:
        return 'cancelled';
    }
  }
}

/// Entidad inmutable de Reporte Ciudadano en EcoRoute.
///
/// Ubicación: `lib/features/citizen/domain/entities/report_entity.dart`
/// Capa: Domain (Entities)
class ReportEntity {
  final String id;
  final String reportNumber;
  final String citizenId;
  final String citizenName;
  final String? citizenPhone;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String description;
  final ReportPriority priority;
  final ReportStatus status;
  final double latitude;
  final double longitude;
  final String address;
  final String? reference;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReportEntity({
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
}
