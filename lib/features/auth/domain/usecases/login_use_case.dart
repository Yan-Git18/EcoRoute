import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para inicio de sesión en EcoRoute.
/// 
/// Ubicación: `lib/features/auth/domain/usecases/login_use_case.dart`
/// Capa: Domain (UseCases)
class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      return const FailureResult(
        ValidationFailure(message: 'Ingrese un correo electrónico válido'),
      );
    }
    if (password.length < 6) {
      return const FailureResult(
        ValidationFailure(message: 'La contraseña debe tener al menos 6 caracteres'),
      );
    }

    return _repository.signInWithEmail(
      email: trimmedEmail,
      password: password,
    );
  }
}
