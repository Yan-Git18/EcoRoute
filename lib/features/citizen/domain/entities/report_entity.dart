import 'package:flutter/material.dart';

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

/// Extensión de atributos visuales para ReportPriority (Principio OCP)
extension ReportPriorityX on ReportPriority {
  String get displayLabel => label;

  Color get color {
    switch (this) {
      case ReportPriority.high:
        return const Color(0xFFDC2626);
      case ReportPriority.medium:
        return const Color(0xFFD97706);
      case ReportPriority.low:
        return const Color(0xFF16A34A);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ReportPriority.high:
        return const Color(0xFFFEE2E2);
      case ReportPriority.medium:
        return const Color(0xFFFEF3C7);
      case ReportPriority.low:
        return const Color(0xFFDCFCE7);
    }
  }

  IconData get icon {
    switch (this) {
      case ReportPriority.high:
        return Icons.warning_amber_rounded;
      case ReportPriority.medium:
        return Icons.error_outline_rounded;
      case ReportPriority.low:
        return Icons.info_outline_rounded;
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

/// Extensión de atributos visuales y ciclo de vida para ReportStatus (Principio OCP).
/// Permite agregar nuevos estados sin modificar los widgets de presentación.
extension ReportStatusX on ReportStatus {
  String get displayLabel {
    switch (this) {
      case ReportStatus.pending:
        return 'En revisión';
      case ReportStatus.assigned:
        return 'Asignado';
      case ReportStatus.inProgress:
        return 'En proceso';
      case ReportStatus.resolved:
        return 'Resuelto';
      case ReportStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ReportStatus.pending:
        return const Color(0xFFE0F2FE);
      case ReportStatus.assigned:
        return const Color(0xFFEDE9FE);
      case ReportStatus.inProgress:
        return const Color(0xFFDBEAFE);
      case ReportStatus.resolved:
        return const Color(0xFFDCFCE7);
      case ReportStatus.cancelled:
        return const Color(0xFFFEE2E2);
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.pending:
        return const Color(0xFF0369A1);
      case ReportStatus.assigned:
        return const Color(0xFF6D28D9);
      case ReportStatus.inProgress:
        return const Color(0xFF1D4ED8);
      case ReportStatus.resolved:
        return const Color(0xFF15803D);
      case ReportStatus.cancelled:
        return const Color(0xFFB91C1C);
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.pending:
        return Icons.schedule_rounded;
      case ReportStatus.assigned:
        return Icons.assignment_ind_rounded;
      case ReportStatus.inProgress:
        return Icons.info_outline_rounded;
      case ReportStatus.resolved:
        return Icons.check_circle_outline_rounded;
      case ReportStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  int get stepOrder {
    switch (this) {
      case ReportStatus.pending:
        return 1;
      case ReportStatus.assigned:
        return 2;
      case ReportStatus.inProgress:
        return 3;
      case ReportStatus.resolved:
        return 4;
      case ReportStatus.cancelled:
        return 0;
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
