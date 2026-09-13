import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para registro de nuevos usuarios en EcoRoute.
/// 
/// Ubicación: `lib/features/auth/domain/usecases/register_use_case.dart`
/// Capa: Domain (UseCases)
class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<Result<UserEntity>> call({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.citizen,
    String? phoneNumber,
  }) async {
    if (name.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'El nombre completo es requerido'),
      );
    }
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

    return _repository.signUpWithEmail(
      name: name.trim(),
      email: trimmedEmail,
      password: password,
      role: role,
      phoneNumber: phoneNumber?.trim(),
    );
  }
}
