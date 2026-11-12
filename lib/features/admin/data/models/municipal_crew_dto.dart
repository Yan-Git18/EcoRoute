import 'package:cloud_firestore/cloud_firestore.dart';
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
  final String vehicleCode;
  final String vehiclePlate;
  final String vehicleType;
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
    required this.vehicleCode,
    required this.vehiclePlate,
    this.vehicleType = 'Camión Compactador',
    this.crewMembersCount = 3,
    this.activeTasksCount = 0,
    this.isAvailable = true,
    this.status = 'available',
    this.latitude = -12.0463,
    this.longitude = -77.0427,
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

    final locationMap = map['location'] as Map<String, dynamic>?;

    return MunicipalCrewDto(
      id: docId,
      name: map['name'] as String? ?? 'Cuadrilla Municipal',
      zone: map['zone'] as String? ?? 'Sector General',
      leadStaffName: map['leadStaffName'] as String? ?? 'Personal Encargado',
      vehicleCode: map['vehicleCode'] as String? ?? 'Unidad #01',
      vehiclePlate: map['vehiclePlate'] as String? ?? 'ECR-000',
      vehicleType: map['vehicleType'] as String? ?? 'Camión Compactador',
      crewMembersCount: (map['crewMembersCount'] as num?)?.toInt() ?? 3,
      activeTasksCount: (map['activeTasksCount'] as num?)?.toInt() ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? true,
      status: map['status'] as String? ?? 'available',
      latitude: (locationMap != null ? locationMap['latitude'] as num? : map['latitude'] as num?)?.toDouble() ?? -12.0463,
      longitude: (locationMap != null ? locationMap['longitude'] as num? : map['longitude'] as num?)?.toDouble() ?? -77.0427,
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
      'vehicleCode': vehicleCode,
      'vehiclePlate': vehiclePlate,
      'vehicleType': vehicleType,
      'crewMembersCount': crewMembersCount,
      'activeTasksCount': activeTasksCount,
      'isAvailable': isAvailable,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
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
      vehicleCode: vehicleCode,
      vehiclePlate: vehiclePlate,
      vehicleType: vehicleType,
      crewMembersCount: crewMembersCount,
      activeTasksCount: activeTasksCount,
      isAvailable: isAvailable,
      status: MunicipalCrewStatus.fromString(status),
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Construye un DTO a partir de la entidad del dominio.
  factory MunicipalCrewDto.fromDomain(MunicipalCrewEntity entity, {DateTime? createdAt, DateTime? updatedAt}) {
    return MunicipalCrewDto(
      id: entity.id,
      name: entity.name,
      zone: entity.zone,
      leadStaffName: entity.leadStaffName,
      vehicleCode: entity.vehicleCode,
      vehiclePlate: entity.vehiclePlate,
      vehicleType: entity.vehicleType,
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

