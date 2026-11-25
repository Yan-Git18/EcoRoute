import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/geo_constants.dart';
import '../../domain/entities/municipal_crew_entity.dart';

/// DTO para la serialización y persistencia de Cuadrillas Municipales en Cloud Firestore.
///
/// Colección de destino: `'crews'`
/// Ubicación: `lib/features/admin/data/models/municipal_crew_dto.dart`
/// Capa: Data (Models)
class MunicipalCrewDto {
  final String id;
  final String name;
  final String zone;
  final String leadStaffName;
  final String? leaderId;
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
  final String status;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MunicipalCrewDto({
    required this.id,
    required this.name,
    required this.zone,
    required this.leadStaffName,
    this.leaderId,
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
    this.status = 'available',
    this.latitude = AppGeoConstants.cajamarcaCenterLat,
    this.longitude = AppGeoConstants.cajamarcaCenterLng,
    this.createdAt,
    this.updatedAt,
  });

  /// Crea un DTO deserializando un documento de Firestore o mapa JSON.
  factory MunicipalCrewDto.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final location = map['location'];
    final (latitude, longitude) = switch (location) {
      GeoPoint() => (location.latitude, location.longitude),
      Map() => (location['latitude'], location['longitude']),
      _ => (map['latitude'], map['longitude']),
    };
    final hasPair = latitude is num && longitude is num;
    final members = (map['memberIds'] as List?)?.whereType<String>().toList();

    return MunicipalCrewDto(
      id: docId,
      name: map['name'] as String? ?? 'Cuadrilla Municipal',
      zone: map['zone'] as String? ?? 'Sector General',
      leadStaffName: map['leadStaffName'] as String? ?? 'Personal Encargado',
      leaderId: map['leaderId'] as String?,
      vehicleCode: map['vehicleCode'] as String? ?? '',
      vehiclePlate: map['vehiclePlate'] as String? ?? '',
      vehicleType: map['vehicleType'] as String? ?? '',
      vehicleId: map['vehicleId'] as String?,
      vehicleOnly: map['vehicleOnly'] == true,
      assignedCrewId: map['assignedCrewId'] as String?,
      memberIds: members,
      crewMembersCount:
          members?.length ??
          (map['memberCount'] as num? ?? map['crewMembersCount'] as num?)
              ?.toInt() ??
          0,
      activeTasksCount:
          (map['openReportCount'] as num? ?? map['activeTasksCount'] as num?)
              ?.toInt() ??
          0,
      isAvailable: map['isAvailable'] as bool? ?? true,
      status: map['status'] as String? ?? 'available',
      latitude: hasPair
          ? latitude.toDouble()
          : AppGeoConstants.cajamarcaCenterLat,
      longitude: hasPair
          ? longitude.toDouble()
          : AppGeoConstants.cajamarcaCenterLng,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  /// Serializa los datos a un mapa compatible con Cloud Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'zone': zone,
      'leadStaffName': leadStaffName,
      if (leaderId != null) 'leaderId': leaderId,
      'vehicleCode': vehicleCode,
      'vehiclePlate': vehiclePlate,
      'vehicleType': vehicleType,
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (vehicleOnly) 'vehicleOnly': true,
      if (assignedCrewId != null) 'assignedCrewId': assignedCrewId,
      if (memberIds != null) 'memberIds': memberIds,
      'crewMembersCount': crewMembersCount,
      'activeTasksCount': activeTasksCount,
      'isAvailable': isAvailable,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'location': {'latitude': latitude, 'longitude': longitude},
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Mapea el DTO a la entidad de dominio pura e inmutable.
  MunicipalCrewEntity toDomain() {
    return MunicipalCrewEntity(
      id: id,
      name: name,
      zone: zone,
      leadStaffName: leadStaffName,
      leaderId: leaderId,
      vehicleCode: vehicleCode,
      vehiclePlate: vehiclePlate,
      vehicleType: vehicleType,
      vehicleId: vehicleId,
      vehicleOnly: vehicleOnly,
      assignedCrewId: assignedCrewId,
      memberIds: memberIds,
      crewMembersCount: crewMembersCount,
      activeTasksCount: activeTasksCount,
      isAvailable: isAvailable,
      status: MunicipalCrewStatus.fromString(status),
      latitude: latitude,
      longitude: longitude,
      updatedAt: updatedAt,
    );
  }

  /// Construye un DTO a partir de la entidad del dominio.
  factory MunicipalCrewDto.fromDomain(
    MunicipalCrewEntity entity, {
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MunicipalCrewDto(
      id: entity.id,
      name: entity.name,
      zone: entity.zone,
      leadStaffName: entity.leadStaffName,
      leaderId: entity.leaderId,
      vehicleCode: entity.vehicleCode,
      vehiclePlate: entity.vehiclePlate,
      vehicleType: entity.vehicleType,
      vehicleId: entity.vehicleId,
      vehicleOnly: entity.vehicleOnly,
      assignedCrewId: entity.assignedCrewId,
      memberIds: entity.memberIds,
      crewMembersCount: entity.crewMembersCount,
      activeTasksCount: entity.activeTasksCount,
      isAvailable: entity.isAvailable,
      status: entity.status.toDbString(),
      latitude: entity.latitude,
      longitude: entity.longitude,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
