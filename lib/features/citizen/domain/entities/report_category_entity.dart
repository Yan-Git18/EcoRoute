/// Entidad representativa de una categoría de reporte de residuos.
///
/// Ubicación: `lib/features/citizen/domain/entities/report_category_entity.dart`
/// Capa: Domain (Entities)
class ReportCategoryEntity {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String defaultPriority;
  final int slaHours;
  final int order;
  final bool isActive;

  const ReportCategoryEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.defaultPriority,
    required this.slaHours,
    required this.order,
    this.isActive = true,
  });

  /// Lista de categorías por defecto
  static const List<ReportCategoryEntity> defaultCategories = [
    ReportCategoryEntity(
      id: 'waste_accumulation',
      name: 'Acumulación de basura',
      description: 'Montículos de residuos en esquinas, veredas o descampados.',
      icon: 'delete_outline_rounded',
      defaultPriority: 'medium',
      slaHours: 24,
      order: 1,
    ),
    ReportCategoryEntity(
      id: 'full_bin',
      name: 'Contenedor lleno',
      description: 'Contenedor público sobrepasado de su capacidad habitual.',
      icon: 'delete_sweep_rounded',
      defaultPriority: 'medium',
      slaHours: 12,
      order: 2,
    ),
    ReportCategoryEntity(
      id: 'waste_public_road',
      name: 'Residuos en vía pública',
      description: 'Desechos dispersos en pistas, bermas o áreas peatonales.',
      icon: 'cleaning_services_rounded',
      defaultPriority: 'medium',
      slaHours: 18,
      order: 3,
    ),
    ReportCategoryEntity(
      id: 'damaged_recycling_point',
      name: 'Punto de reciclaje deteriorado',
      description: 'Estación de reciclaje rota, vandalizada o sin segregación.',
      icon: 'recycling_rounded',
      defaultPriority: 'low',
      slaHours: 48,
      order: 4,
    ),
    ReportCategoryEntity(
      id: 'damaged_container',
      name: 'Contenedor dañado',
      description: 'Tacho o contenedor municipal roto, quemado o sin tapa.',
      icon: 'restore_from_trash_rounded',
      defaultPriority: 'medium',
      slaHours: 36,
      order: 5,
    ),
    ReportCategoryEntity(
      id: 'other_issue',
      name: 'Otro problema',
      description: 'Cualquier otra incidencia ambiental o de residuos no listada.',
      icon: 'warning_amber_rounded',
      defaultPriority: 'low',
      slaHours: 48,
      order: 6,
    ),
  ];
}
