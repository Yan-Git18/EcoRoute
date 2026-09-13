import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para enviar correo de restablecimiento de contraseña.
/// 
/// Ubicación: `lib/features/auth/domain/usecases/send_password_reset_email_use_case.dart`
/// Capa: Domain (UseCases)
class SendPasswordResetEmailUseCase {
  final AuthRepository _repository;

  const SendPasswordResetEmailUseCase(this._repository);

  Future<Result<void>> call(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      return const FailureResult(
        ValidationFailure(message: 'Ingrese un correo electrónico válido'),
      );
    }

    return _repository.sendPasswordResetEmail(trimmedEmail);
  }
}
