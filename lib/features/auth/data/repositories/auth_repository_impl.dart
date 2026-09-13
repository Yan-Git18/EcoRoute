import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementación del repositorio de autenticación en la capa Data.
/// 
/// Ubicación: `lib/features/auth/data/repositories/auth_repository_impl.dart`
/// Capa: Data (Repositories)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  const AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userDto = await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Success(userDto.toDomain());
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  Future<Result<UserEntity>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.citizen,
    String? phoneNumber,
  }) async {
    try {
      final userDto = await _remoteDataSource.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        role: role.toDbString(),
        phoneNumber: phoneNumber,
      );
      return Success(userDto.toDomain());
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al cerrar sesión: $e'));
    }
  }

  @override
  Future<Result<UserEntity?>> getCurrentUser() async {
    try {
      final userDto = await _remoteDataSource.getCurrentUser();
      return Success(userDto?.toDomain());
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al consultar sesión: $e'));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(ServerFailure(message: 'Error al enviar recuperación: $e'));
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return _remoteDataSource.authStateChanges().map((dto) => dto?.toDomain());
  }
}
