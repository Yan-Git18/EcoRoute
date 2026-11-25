import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/admin_profile_repository.dart';

class FirebaseAdminProfileRepository implements AdminProfileRepository {
  const FirebaseAdminProfileRepository();

  User? _currentUser(String uid) {
    if (Firebase.apps.isEmpty) return null;
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid == uid ? user : null;
  }

  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  @override
  Future<Result<UserEntity>> saveContact(
    UserEntity account, {
    required String name,
    required String? phone,
  }) async {
    if (!account.isAdmin || _currentUser(account.id) == null) {
      return _sessionFailure();
    }
    try {
      await _profile(account.id).update({
        'name': name,
        'phoneNumber': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Success(
        account.copyWith(
          name: name,
          phoneNumber: phone,
          clearPhoneNumber: phone == null,
        ),
      );
    } on FirebaseException catch (error) {
      return FailureResult(
        ServerFailure(
          message: 'No se pudieron guardar los datos del perfil.',
          code: error.code,
        ),
      );
    }
  }

  @override
  Future<Result<void>> requestEmailChange(
    String uid, {
    required String email,
    required String password,
  }) async {
    final user = _currentUser(uid);
    final currentEmail = user?.email;
    if (user == null || currentEmail == null) return _sessionFailure();
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: currentEmail, password: password),
      );
      if (_currentUser(uid) == null) return _sessionFailure();
      await user.verifyBeforeUpdateEmail(email);
      return const Success(null);
    } on FirebaseAuthException catch (error) {
      final message = switch (error.code) {
        'invalid-credential' ||
        'wrong-password' => 'La contraseña actual no es correcta.',
        'email-already-in-use' => 'El correo ya está vinculado a una cuenta.',
        'invalid-email' => 'Escribe un correo válido.',
        'too-many-requests' =>
          'Demasiados intentos. Vuelve a intentarlo más tarde.',
        _ => 'No se pudo enviar el enlace de confirmación.',
      };
      return FailureResult(ServerFailure(message: message, code: error.code));
    }
  }

  @override
  Future<Result<String>> refreshEmail(String uid) async {
    final user = _currentUser(uid);
    if (user == null) return _sessionFailure();
    try {
      await user.reload();
      final refreshed = _currentUser(uid);
      final email = refreshed?.email;
      if (refreshed == null || email == null) return _sessionFailure();
      if (refreshed.emailVerified) {
        final profile = _profile(uid);
        final data = (await profile.get(
          const GetOptions(source: Source.server),
        )).data();
        if (data?['email'] != email) {
          await refreshed.getIdToken(true);
          await profile.update({
            'email': email,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return Success(email);
    } on FirebaseAuthException catch (error) {
      if (const [
        'user-token-expired',
        'invalid-user-token',
        'requires-recent-login',
      ].contains(error.code)) {
        return _sessionFailure();
      }
      return FailureResult(
        ServerFailure(
          message: 'No se pudo comprobar el correo registrado.',
          code: error.code,
        ),
      );
    } on FirebaseException catch (error) {
      return FailureResult(
        ServerFailure(
          message: 'No se pudo sincronizar el correo del perfil.',
          code: error.code,
        ),
      );
    }
  }

  FailureResult<T> _sessionFailure<T>() => FailureResult(
    const ServerFailure(message: 'Vuelve a iniciar sesión para continuar.'),
  );
}
