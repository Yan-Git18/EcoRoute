import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';

/// Contrato abstracto del repositorio de autenticación.
/// 
/// Ubicación: `lib/features/auth/domain/repositories/auth_repository.dart`
/// Capa: Domain (Repositories)
abstract class AuthRepository {
  /// Inicia sesión con correo y contraseña.
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registra un nuevo usuario con rol (por defecto ciudadano).
  Future<Result<UserEntity>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.citizen,
    String? phoneNumber,
  });

  /// Cierra la sesión activa.
  Future<Result<void>> signOut();

  /// Obtiene el usuario autenticado actualmente en sesión.
  Future<Result<UserEntity?>> getCurrentUser();

  /// Envía correo de restablecimiento de contraseña.
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Stream reactivo de cambios de estado de autenticación.
  Stream<UserEntity?> authStateChanges();
}
