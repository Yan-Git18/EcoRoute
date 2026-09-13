import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_dto.dart';

/// Contrato abstracto para la fuente de datos remota de autenticación.
/// 
/// Ubicación: `lib/features/auth/data/datasources/auth_remote_datasource.dart`
/// Capa: Data (DataSources)
abstract class AuthRemoteDataSource {
  Future<UserDto> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserDto> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  });

  Future<void> signOut();

  Future<UserDto?> getCurrentUser();

  Future<void> sendPasswordResetEmail(String email);

  Stream<UserDto?> authStateChanges();
}

/// Implementación de AuthRemoteDataSource con Firebase (FirebaseAuth + Cloud Firestore).
class FirebaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth? _customFirebaseAuth;
  final FirebaseFirestore? _customFirestore;

  FirebaseAuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _customFirebaseAuth = firebaseAuth,
        _customFirestore = firestore;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseAuth get _firebaseAuth => _customFirebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  void _assertFirebaseConfigured() {
    if (!_isFirebaseReady && _customFirebaseAuth == null) {
      throw const AuthException(
        message: 'Firebase no está inicializado aún en este dispositivo. Utilice los botones de Demostración Rápida para explorar los roles.',
        code: 'firebase-not-configured',
      );
    }
  }

  @override
  Future<UserDto> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _assertFirebaseConfigured();
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(message: 'No se pudo autenticar el usuario');
      }

      // Obtener datos del perfil en Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        // Si el usuario existe en Auth pero no en Firestore, crear un registro básico
        final newDto = UserDto(
          id: user.uid,
          name: user.displayName ?? email.split('@').first,
          email: email,
          role: 'citizen',
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(user.uid).set(newDto.toMap());
        return newDto;
      }

      return UserDto.fromMap(doc.data()!, doc.id);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthException(message: 'Error inesperado al iniciar sesión: $e');
    }
  }

  @override
  Future<UserDto> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    _assertFirebaseConfigured();
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(message: 'Error al registrar credenciales en Firebase');
      }

      await user.updateDisplayName(name);

      final userDto = UserDto(
        id: user.uid,
        name: name,
        email: email,
        role: role,
        phoneNumber: phoneNumber,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Guardar perfil en Cloud Firestore colección 'users'
      await _firestore.collection('users').doc(user.uid).set(userDto.toMap());

      return userDto;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthException(message: 'Error al registrar cuenta: $e');
    }
  }

  @override
  Future<void> signOut() async {
    if (!_isFirebaseReady && _customFirebaseAuth == null) return;
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException(message: 'Error al cerrar sesión: $e');
    }
  }

  @override
  Future<UserDto?> getCurrentUser() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return null;

      final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!doc.exists || doc.data() == null) return null;

      return UserDto.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
      );
    }
  }

  @override
  Stream<UserDto?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          return UserDto.fromMap(doc.data()!, doc.id);
        }
        return null;
      } catch (_) {
        return null;
      }
    });
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos';
      case 'email-already-in-use':
        return 'Ya existe una cuenta registrada con este correo electrónico';
      case 'invalid-email':
        return 'El formato de correo no es válido';
      case 'weak-password':
        return 'La contraseña es muy débil. Ingrese mínimo 6 caracteres';
      case 'user-disabled':
        return 'Esta cuenta ha sido inhabilitada por un administrador';
      case 'network-request-failed':
        return 'Fallo de conexión a internet. Verifique su red';
      default:
        return 'Ocurrió un error en el servicio de autenticación ($code)';
    }
  }
}
