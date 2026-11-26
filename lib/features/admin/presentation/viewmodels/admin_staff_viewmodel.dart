import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_reports_viewmodel.dart';
import 'admin_staff_state.dart';

/// Provider para el ViewModel de gestión de personal municipal (Admin).
final adminStaffViewModelProvider =
    NotifierProvider.autoDispose<AdminStaffViewModel, AdminStaffState>(
      AdminStaffViewModel.new,
    );

/// ViewModel que encapsula la lógica de negocio para la gestión segura de trabajadores.
///
/// Principio de Privacidad:
/// - Solo consulta y expone usuarios con rol 'staff'.
/// - La búsqueda requiere coincidencia exacta de correo, protegiendo las identidades ciudadanas.
class AdminStaffViewModel extends Notifier<AdminStaffState> {
  late AdminRepository _repository;
  int _searchVersion = 0;

  @override
  AdminStaffState build() {
    _repository = ref.watch(adminRepositoryProvider);
    _searchVersion++;
    final routeRef = ref;
    Future.microtask(() {
      if (routeRef.mounted) loadInitialData();
    });
    return const AdminStaffState(isLoading: true);
  }

  /// Carga el personal municipal.
  Future<void> loadInitialData() async {
    if (state.isUpdating) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getStaffMembers();
    if (!ref.mounted) return;
    state = state.copyWith(
      isLoading: false,
      staffMembers: result.dataOrNull?.where((staff) => staff.isActive).toList(),
      errorMessage: result.failureOrNull?.message,
    );
  }

  /// Búsqueda privada por coincidencia exacta de correo electrónico.
  Future<void> searchExactEmail(String email) async {
    final searchVersion = ++_searchVersion;
    final routeRef = ref;
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        isSearching: false,
        clearSearchedUser: true,
        hasSearched: false,
        errorMessage: 'Por favor ingresa un correo electrónico.',
      );
      return;
    }

    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      state = state.copyWith(
        isSearching: false,
        clearSearchedUser: true,
        hasSearched: false,
        errorMessage: 'Ingresa un formato de correo válido (ej. usuario@gmail.com).',
      );
      return;
    }

    state = state.copyWith(
      isSearching: true,
      clearSearchedUser: true,
      hasSearched: false,
      clearError: true,
      clearSuccess: true,
    );

    final result = await _repository.searchUserByExactEmail(trimmed);
    if (!routeRef.mounted || searchVersion != _searchVersion) return;

    switch (result) {
      case Success(data: final user):
        state = state.copyWith(
          isSearching: false,
          searchedUser: user,
          clearSearchedUser: user == null,
          hasSearched: true,
          searchedEmail: trimmed,
        );
      case FailureResult(failure: final f):
        state = state.copyWith(
          isSearching: false,
          clearSearchedUser: true,
          hasSearched: true,
          searchedEmail: trimmed,
          errorMessage: f.message,
        );
    }
  }

  /// Limpia los resultados de búsqueda actual.
  void clearSearch() {
    _searchVersion++;
    state = state.copyWith(
      isSearching: false,
      clearSearchedUser: true,
      hasSearched: false,
      clearError: true,
      clearSuccess: true,
    );
  }

  Future<bool> promoteToStaff(UserEntity user) async {
    if (state.isUpdating || !user.isCitizen) return false;
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);
    final result = await _repository.updateUserRole(
      userId: user.id,
      newRole: UserRole.staff,
    );
    if (!ref.mounted) return false;
    switch (result) {
      case Success():
        final updated = user.copyWith(role: UserRole.staff);
        state = state.copyWith(
          isUpdating: false,
          staffMembers: [if (updated.isActive) updated, ...state.staffMembers.where((staff) => staff.id != user.id)],
          searchedUser: state.searchedUser?.id == user.id ? updated : null,
          successMessage: '${user.name} ahora es personal de limpieza.',
        );
        return true;
      case FailureResult(failure: final failure):
        state = state.copyWith(isUpdating: false, errorMessage: failure.message);
        return false;
    }
  }

  /// Revierte a un miembro del personal al rol 'citizen'.
  Future<bool> demoteToCitizen(UserEntity user) async {
    if (state.isUpdating) return false;
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);

    final result = await _repository.updateUserRole(
      userId: user.id,
      newRole: UserRole.citizen,
    );
    if (!ref.mounted) return false;

    switch (result) {
      case Success():
        final updatedUser = user.copyWith(role: UserRole.citizen, clearTeamId: true);
        final currentList = state.staffMembers.where((u) => u.id != user.id).toList();

        state = state.copyWith(
          isUpdating: false,
          staffMembers: currentList,
          searchedUser: state.searchedUser?.id == user.id ? updatedUser : state.searchedUser,
          successMessage: 'Rol de ${user.name} revertido a Ciudadano.',
        );
        return true;
      case FailureResult(failure: final f):
        state = state.copyWith(
          isUpdating: false,
          errorMessage: 'Error al cambiar rol: ${f.message}',
        );
        return false;
    }
  }
}
