/// Rol del usuario en EcoRoute
enum UserRole {
  citizen,
  staff,
  admin;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'staff':
      case 'personal':
        return UserRole.staff;
      case 'admin':
      case 'administrador':
        return UserRole.admin;
      case 'citizen':
      case 'ciudadano':
      default:
        return UserRole.citizen;
    }
  }

  String toDbString() {
    switch (this) {
      case UserRole.staff:
        return 'staff';
      case UserRole.admin:
        return 'admin';
      case UserRole.citizen:
        return 'citizen';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.citizen:
        return 'Ciudadano';
      case UserRole.staff:
        return 'Personal de Limpieza';
      case UserRole.admin:
        return 'Administrador Municipal';
    }
  }
}

/// Entidad pura de Usuario en el dominio.
/// 
/// Ubicación: `lib/features/auth/domain/entities/user_entity.dart`
/// Capa: Domain (Entities)
class UserEntity {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phoneNumber;
  final String? photoUrl;
  final String? teamId;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
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

  bool get isCitizen => role == UserRole.citizen;
  bool get isStaff => role == UserRole.staff;
  bool get isAdmin => role == UserRole.admin;

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phoneNumber,
    String? photoUrl,
    String? teamId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      teamId: teamId ?? this.teamId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
