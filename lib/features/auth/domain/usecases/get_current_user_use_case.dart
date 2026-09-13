import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para obtener el usuario actual y escuchar cambios de sesión.
/// 
/// Ubicación: `lib/features/auth/domain/usecases/get_current_user_use_case.dart`
/// Capa: Domain (UseCases)
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  Future<Result<UserEntity?>> call() async {
    return _repository.getCurrentUser();
  }

  Stream<UserEntity?> authStateChanges() {
    return _repository.authStateChanges();
  }
}
