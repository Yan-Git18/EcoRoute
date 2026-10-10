/// Estado operativo de una cuadrilla municipal.
enum MunicipalCrewStatus {
  available('Disponible'),
  onRoute('En Ruta'),
  maintenance('En Mantenimiento');

  final String label;
  const MunicipalCrewStatus(this.label);
}

/// Entidad inmutable que representa una Cuadrilla de Limpieza Municipal y su unidad vehicular.
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
  final String vehicleType;
  final int crewMembersCount;
  final int activeTasksCount;
  final bool isAvailable;
  final MunicipalCrewStatus status;
  final double latitude;
  final double longitude;

  const MunicipalCrewEntity({
    required this.id,
    required this.name,
    required this.zone,
    required this.leadStaffName,
    required this.vehicleCode,
    required this.vehiclePlate,
    this.vehicleType = 'Camión Compactador',
    this.crewMembersCount = 3,
    this.activeTasksCount = 0,
    this.isAvailable = true,
    this.status = MunicipalCrewStatus.available,
    this.latitude = -12.0463,
    this.longitude = -77.0427,
  });

  MunicipalCrewEntity copyWith({
    String? id,
    String? name,
    String? zone,
    String? leadStaffName,
    String? vehicleCode,
    String? vehiclePlate,
    String? vehicleType,
    int? crewMembersCount,
    int? activeTasksCount,
    bool? isAvailable,
    MunicipalCrewStatus? status,
    double? latitude,
    double? longitude,
  }) {
    return MunicipalCrewEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      zone: zone ?? this.zone,
      leadStaffName: leadStaffName ?? this.leadStaffName,
      vehicleCode: vehicleCode ?? this.vehicleCode,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      crewMembersCount: crewMembersCount ?? this.crewMembersCount,
      activeTasksCount: activeTasksCount ?? this.activeTasksCount,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
