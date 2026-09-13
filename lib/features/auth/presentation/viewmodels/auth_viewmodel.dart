import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/register_use_case.dart';
import '../../domain/usecases/send_password_reset_email_use_case.dart';
import 'auth_state.dart';

// --- Inyección de Dependencias con Riverpod ---

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return FirebaseAuthRemoteDataSourceImpl();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterUseCase(repository);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

final sendPasswordResetEmailUseCaseProvider = Provider<SendPasswordResetEmailUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendPasswordResetEmailUseCase(repository);
});

// --- ViewModel (MVVM) ---

/// ViewModel para la gestión del flujo de autenticación y estado del usuario.
/// 
/// Ubicación: `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart`
/// Capa: Presentation (ViewModel)
class AuthViewModel extends Notifier<AuthState> {
  late final LoginUseCase _loginUseCase;
  late final RegisterUseCase _registerUseCase;
  late final LogoutUseCase _logoutUseCase;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final SendPasswordResetEmailUseCase _sendPasswordResetEmailUseCase;

  @override
  AuthState build() {
    _loginUseCase = ref.watch(loginUseCaseProvider);
    _registerUseCase = ref.watch(registerUseCaseProvider);
    _logoutUseCase = ref.watch(logoutUseCaseProvider);
    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
    _sendPasswordResetEmailUseCase = ref.watch(sendPasswordResetEmailUseCaseProvider);

    // Verificación inicial de sesión asíncrona
    Future.microtask(() => checkCurrentSession());

    return AuthState.initial();
  }

  /// Verifica si existe una sesión activa persistida
  Future<void> checkCurrentSession() async {
    final result = await _getCurrentUserUseCase.call();
    result.fold(
      onSuccess: (user) {
        state = state.copyWith(
          user: user,
          isInitialized: true,
          clearError: true,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isInitialized: true,
          clearError: true,
        );
      },
    );
  }

  /// Inicia sesión con correo y contraseña
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _loginUseCase.call(
      email: email,
      password: password,
    );

    return result.fold(
      onSuccess: (user) {
        state = state.copyWith(
          isLoading: false,
          user: user,
          clearError: true,
        );
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  /// Registra un nuevo usuario
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.citizen,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _registerUseCase.call(
      name: name,
      email: email,
      password: password,
      role: role,
      phoneNumber: phoneNumber,
    );

    return result.fold(
      onSuccess: (user) {
        state = state.copyWith(
          isLoading: false,
          user: user,
          clearError: true,
        );
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  /// Envía correo para restablecer la contraseña
  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _sendPasswordResetEmailUseCase.call(email);

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false, clearError: true);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  /// Cierra la sesión
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _logoutUseCase.call();
    state = state.copyWith(
      isLoading: false,
      clearUser: true,
      clearError: true,
    );
  }

  /// Limpia cualquier mensaje de error activo en la UI
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  /// Método para fines de prueba y demostración rápida de roles en desarrollo
  void setDemoRole(UserRole role) {
    final demoUser = UserEntity(
      id: 'demo-${role.name}-101',
      name: switch (role) {
        UserRole.citizen => 'Carlos Ciudadano',
        UserRole.staff => 'Mario Limpieza',
        UserRole.admin => 'Ing. Municipal Admin',
      },
      email: 'demo.${role.name}@ecoroute.app',
      role: role,
      phoneNumber: '+51 987654321',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(user: demoUser, clearError: true);
  }
}

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
