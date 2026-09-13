import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para cerrar la sesión activa.
/// 
/// Ubicación: `lib/features/auth/domain/usecases/logout_use_case.dart`
/// Capa: Domain (UseCases)
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<Result<void>> call() async {
    return _repository.signOut();
  }
}
