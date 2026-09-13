import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// DTO (Data Transfer Object) para serialización de usuarios en Firestore.
/// 
/// Ubicación: `lib/features/auth/data/models/user_dto.dart`
/// Capa: Data (Models / DTOs)
class UserDto {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phoneNumber;
  final String? photoUrl;
  final String? teamId;
  final bool isActive;
  final DateTime createdAt;

  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.photoUrl,
    this.teamId,
    this.isActive = true,
    required this.createdAt,
  });

  /// Factory para construir a partir de un mapa o snapshot de Firestore
  factory UserDto.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserDto(
      id: documentId,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'citizen',
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String?,
      teamId: map['teamId'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
    );
  }

  /// Serialización a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'teamId': teamId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Conversión de DTO a Entidad de Dominio pura
  UserEntity toDomain() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      role: UserRole.fromString(role),
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      teamId: teamId,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  /// Conversión de Entidad de Dominio a DTO
  factory UserDto.fromDomain(UserEntity entity) {
    return UserDto(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      role: entity.role.toDbString(),
      phoneNumber: entity.phoneNumber,
      photoUrl: entity.photoUrl,
      teamId: entity.teamId,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}
