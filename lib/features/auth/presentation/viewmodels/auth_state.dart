import '../../domain/entities/user_entity.dart';

/// Estado inmutable de la UI para el flujo de autenticación.
/// 
/// Ubicación: `lib/features/auth/presentation/viewmodels/auth_state.dart`
/// Capa: Presentation (State)
class AuthState {
  final bool isLoading;
  final UserEntity? user;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    UserEntity? user,
    String? errorMessage,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  factory AuthState.initial() => const AuthState();
}
