import 'package:flutter/foundation.dart';

import '../../../../core/constants/geo_constants.dart';

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
  static const minMembers = 2;
  static const maxMembers = 5;

  static bool isValidMemberCount(int count) =>
      count >= minMembers && count <= maxMembers;

  final String id;
  final String name;
  final String zone;
  final String leadStaffName;
  final String vehicleCode;
  final String vehiclePlate;
  final String vehicleType;
  final String? vehicleId;
  final bool vehicleOnly;
  final String? assignedCrewId;
  final List<String>? memberIds;
  final int crewMembersCount;
  final int activeTasksCount;
  final bool isAvailable;
  final MunicipalCrewStatus status;
  final double latitude;
  final double longitude;
  final DateTime? updatedAt;

  const MunicipalCrewEntity({
    required this.id,
    required this.name,
    required this.zone,
    required this.leadStaffName,
    required this.vehicleCode,
    required this.vehiclePlate,
    this.vehicleType = 'Camión Compactador',
    this.vehicleId,
    this.vehicleOnly = false,
    this.assignedCrewId,
    this.memberIds,
    this.crewMembersCount = 3,
    this.activeTasksCount = 0,
    this.isAvailable = true,
    this.status = MunicipalCrewStatus.available,
    this.latitude = AppGeoConstants.cajamarcaCenterLat,
    this.longitude = AppGeoConstants.cajamarcaCenterLng,
    this.updatedAt,
  });

  bool get canDispatchVehicle =>
      isAvailable && status == MunicipalCrewStatus.available;

  bool get hasLocation =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      (latitude != 0 || longitude != 0) &&
      (latitude != AppGeoConstants.cajamarcaCenterLat ||
          longitude != AppGeoConstants.cajamarcaCenterLng);

  bool get canDispatch =>
      !vehicleOnly && canDispatchVehicle && activeTasksCount == 0;

  MunicipalCrewEntity copyWith({
    String? id,
    String? name,
    String? zone,
    String? leadStaffName,
    String? vehicleCode,
    String? vehiclePlate,
    String? vehicleType,
    String? vehicleId,
    List<String>? memberIds,
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
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleOnly: vehicleOnly,
      assignedCrewId: assignedCrewId,
      memberIds: memberIds ?? this.memberIds,
      crewMembersCount: crewMembersCount ?? this.crewMembersCount,
      activeTasksCount: activeTasksCount ?? this.activeTasksCount,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt,
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
          vehicleId == other.vehicleId &&
          vehicleOnly == other.vehicleOnly &&
          assignedCrewId == other.assignedCrewId &&
          listEquals(memberIds, other.memberIds) &&
          crewMembersCount == other.crewMembersCount &&
          activeTasksCount == other.activeTasksCount &&
          isAvailable == other.isAvailable &&
          status == other.status &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      zone.hashCode ^
      leadStaffName.hashCode ^
      vehicleCode.hashCode ^
      vehiclePlate.hashCode ^
      vehicleType.hashCode ^
      vehicleId.hashCode ^
      vehicleOnly.hashCode ^
      assignedCrewId.hashCode ^
      Object.hashAll(memberIds ?? const <String>[]) ^
      crewMembersCount.hashCode ^
      activeTasksCount.hashCode ^
      isAvailable.hashCode ^
      status.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      updatedAt.hashCode;
}
