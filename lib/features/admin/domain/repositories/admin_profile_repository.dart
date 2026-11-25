import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract interface class AdminProfileRepository {
  Future<Result<UserEntity>> saveContact(
    UserEntity account, {
    required String name,
    required String? phone,
  });

  Future<Result<void>> requestEmailChange(
    String uid, {
    required String email,
    required String password,
  });

  Future<Result<String>> refreshEmail(String uid);
}
