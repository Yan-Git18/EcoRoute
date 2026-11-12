import '../../domain/entities/report_category_entity.dart';

/// DTO para serialización y deserialización de categorías de reportes en Cloud Firestore.
///
/// Principio Clean Architecture y DRY: Extiende [ReportCategoryEntity] para evitar
/// duplicación de campos del modelo de dominio en la capa de datos.
/// Ubicación: `lib/features/citizen/data/models/report_category_dto.dart`
/// Capa: Data (Models)
class ReportCategoryDto extends ReportCategoryEntity {
  const ReportCategoryDto({
    required super.id,
    required super.name,
    required super.description,
    required super.icon,
    required super.defaultPriority,
    required super.slaHours,
    required super.order,
    super.isActive = true,
  });

  factory ReportCategoryDto.fromFirestore(String id, Map<String, dynamic> data) {
    return ReportCategoryDto(
      id: id,
      name: data['name'] as String? ?? 'Sin nombre',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? 'warning_amber_rounded',
      defaultPriority: data['defaultPriority'] as String? ?? 'medium',
      slaHours: (data['slaHours'] as num?)?.toInt() ?? 24,
      order: (data['order'] as num?)?.toInt() ?? 99,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'defaultPriority': defaultPriority,
      'slaHours': slaHours,
      'order': order,
      'isActive': isActive,
    };
  }

  ReportCategoryEntity toEntity() => this;

  factory ReportCategoryDto.fromEntity(ReportCategoryEntity entity) {
    return ReportCategoryDto(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      icon: entity.icon,
      defaultPriority: entity.defaultPriority,
      slaHours: entity.slaHours,
      order: entity.order,
      isActive: entity.isActive,
    );
  }
}
