import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/citizen_profile_update.dart';

abstract interface class CitizenProfileRepository {
  Future<Result<UserEntity>> update(String userId, CitizenProfileUpdate update);
}
