/// Estado operativo de una cuadrilla municipal.
enum MunicipalCrewStatus {
  available('Disponible'),
  onRoute('En Ruta'),
  maintenance('En Mantenimiento');

  final String label;
  const MunicipalCrewStatus(this.label);

  String toDbString() => name;

  static MunicipalCrewStatus fromString(String? value) {
    switch (value) {
      case 'onRoute':
      case 'on_route':
        return MunicipalCrewStatus.onRoute;
      case 'maintenance':
        return MunicipalCrewStatus.maintenance;
      case 'available':
      default:
        return MunicipalCrewStatus.available;
    }
  }
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MunicipalCrewEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          zone == other.zone &&
          leadStaffName == other.leadStaffName &&
          vehicleCode == other.vehicleCode &&
          vehiclePlate == other.vehiclePlate &&
          vehicleType == other.vehicleType &&
          crewMembersCount == other.crewMembersCount &&
          activeTasksCount == other.activeTasksCount &&
          isAvailable == other.isAvailable &&
          status == other.status &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      zone.hashCode ^
      leadStaffName.hashCode ^
      vehicleCode.hashCode ^
      vehiclePlate.hashCode ^
      vehicleType.hashCode ^
      crewMembersCount.hashCode ^
      activeTasksCount.hashCode ^
      isAvailable.hashCode ^
      status.hashCode ^
      latitude.hashCode ^
      longitude.hashCode;
}
