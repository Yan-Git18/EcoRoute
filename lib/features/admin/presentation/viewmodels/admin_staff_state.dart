import '../../../auth/domain/entities/user_entity.dart';

/// Estado inmutable para la gestión de personal municipal (Admin).
///
/// Ubicación: `lib/features/admin/presentation/viewmodels/admin_staff_state.dart`
/// Capa: Presentation (ViewModels)
class AdminStaffState {
  final bool isLoading;
  final bool isSearching;
  final bool isUpdating;
  final List<UserEntity> staffMembers;
  final UserEntity? searchedUser;
  final bool hasSearched;
  final String? searchedEmail;
  final String? errorMessage;
  final String? successMessage;

  const AdminStaffState({
    this.isLoading = false,
    this.isSearching = false,
    this.isUpdating = false,
    this.staffMembers = const [],
    this.searchedUser,
    this.hasSearched = false,
    this.searchedEmail,
    this.errorMessage,
    this.successMessage,
  });

  AdminStaffState copyWith({
    bool? isLoading,
    bool? isSearching,
    bool? isUpdating,
    List<UserEntity>? staffMembers,
    UserEntity? searchedUser,
    bool clearSearchedUser = false,
    bool? hasSearched,
    String? searchedEmail,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return AdminStaffState(
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      isUpdating: isUpdating ?? this.isUpdating,
      staffMembers: staffMembers ?? this.staffMembers,
      searchedUser: clearSearchedUser ? null : (searchedUser ?? this.searchedUser),
      hasSearched: hasSearched ?? this.hasSearched,
      searchedEmail: searchedEmail ??
          (clearSearchedUser ? null : this.searchedEmail),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}
