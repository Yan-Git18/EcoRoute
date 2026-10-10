/// Entidad inmutable que representa una Cuadrilla de Limpieza Municipal disponible.
///
/// Ubicación: `lib/features/admin/domain/entities/municipal_crew_entity.dart`
/// Capa: Domain (Admin)
class MunicipalCrewEntity {
  final String id;
  final String name;
  final String zone;
  final String leadStaffName;
  final String vehicleCode;
  final String vehiclePlate;
  final int activeTasksCount;
  final bool isAvailable;

  const MunicipalCrewEntity({
    required this.id,
    required this.name,
    required this.zone,
    required this.leadStaffName,
    required this.vehicleCode,
    required this.vehiclePlate,
    this.activeTasksCount = 0,
    this.isAvailable = true,
  });

  MunicipalCrewEntity copyWith({
    String? id,
    String? name,
    String? zone,
    String? leadStaffName,
    String? vehicleCode,
    String? vehiclePlate,
    int? activeTasksCount,
    bool? isAvailable,
  }) {
    return MunicipalCrewEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      zone: zone ?? this.zone,
      leadStaffName: leadStaffName ?? this.leadStaffName,
      vehicleCode: vehicleCode ?? this.vehicleCode,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      activeTasksCount: activeTasksCount ?? this.activeTasksCount,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
