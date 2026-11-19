import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/firestore_media.dart';
import '../../../../core/services/image_compression.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/citizen_profile_update.dart';
import '../../domain/repositories/citizen_profile_repository.dart';

class FirebaseCitizenProfileRepository implements CitizenProfileRepository {
  @override
  Future<Result<UserEntity>> update(
    String userId,
    CitizenProfileUpdate update,
  ) async {
    final validation =
        CitizenProfileUpdate.validateName(update.name) ??
        CitizenProfileUpdate.validatePhone(update.phone);
    if (validation != null) {
      return FailureResult(ValidationFailure(message: validation));
    }
    final photo = update.photo;
    final contentType = photo == null
        ? null
        : CitizenProfileUpdate.photoContentType(photo);
    if (photo != null && contentType == null) {
      return const FailureResult(
        ValidationFailure(
          message: 'Elige una imagen JPG, PNG o WebP de hasta 5 MB.',
        ),
      );
    }
    if (Firebase.apps.isEmpty ||
        FirebaseAuth.instance.currentUser?.uid != userId) {
      return const FailureResult(
        AuthFailure(message: 'Inicia sesión para editar tus datos.'),
      );
    }

    final firestore = FirebaseFirestore.instance;
    final profile = firestore.collection('users').doc(userId);
    try {
      final avatar = photo == null
          ? null
          : await compressPhoto(photo, PhotoSize.avatar);
      final name = update.name.trim();
      final phone = update.phone.trim();
      final changes = <String, dynamic>{
        'name': name,
        'phoneNumber': phone.isEmpty ? null : phone,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final avatarRef = profile.collection('media').doc('avatar');
      if (avatar != null) {
        changes['avatarPath'] = avatarRef.path;
      }
      final user = await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(profile);
        final data = snapshot.data();
        if (data == null) throw StateError('Profile does not exist');
        final saved = UserDto.fromMap({...data, ...changes}, userId).toDomain();
        if (avatar != null) {
          transaction.set(avatarRef, FirestoreMedia.document(avatar));
        }
        transaction.update(profile, changes);
        return saved;
      });
      return Success(user);
    } on PhotoCompressionException catch (error) {
      return FailureResult(ValidationFailure(message: error.message));
    } catch (_) {
      return const FailureResult(
        ServerFailure(
          message: 'No se pudieron guardar tus datos. Inténtalo de nuevo.',
        ),
      );
    }
  }
}
