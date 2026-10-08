import '../../../../core/router/route_names.dart';

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

/// Extensión de políticas de enrutamiento por Rol (Principio OCP).
///
/// Permite extender el sistema agregando nuevos roles con sus propias rutas
/// sin modificar la lógica interna del enrutador central.
extension UserRoleRoutePolicy on UserRole {
  /// Ruta principal por defecto asociada al rol
  String get defaultRoute {
    switch (this) {
      case UserRole.citizen:
        return RouteNames.citizenHome;
      case UserRole.staff:
        return RouteNames.staffHome;
      case UserRole.admin:
        return RouteNames.adminDashboard;
    }
  }

  /// Prefijos de rutas permitidas para este rol
  List<String> get allowedPrefixes {
    switch (this) {
      case UserRole.citizen:
        return ['/citizen'];
      case UserRole.staff:
        return ['/staff'];
      case UserRole.admin:
        return ['/admin'];
    }
  }

  /// Determina si una ruta está autorizada para el rol actual
  bool isRoutePermitted(String currentPath) {
    final isRoleProtected = currentPath.startsWith('/citizen') ||
        currentPath.startsWith('/staff') ||
        currentPath.startsWith('/admin');

    if (!isRoleProtected) return true;

    return allowedPrefixes.any((prefix) => currentPath.startsWith(prefix));
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
