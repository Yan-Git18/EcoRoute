import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_reports_viewmodel.dart';
import 'admin_staff_state.dart';

/// Provider para el ViewModel de gestión de personal municipal (Admin).
final adminStaffViewModelProvider =
    NotifierProvider<AdminStaffViewModel, AdminStaffState>(() {
  return AdminStaffViewModel();
});

/// ViewModel que encapsula la lógica de negocio para la gestión segura de trabajadores.
///
/// Principio de Privacidad:
/// - Solo consulta y expone usuarios con rol 'staff'.
/// - La búsqueda requiere coincidencia exacta de correo, protegiendo las identidades ciudadanas.
class AdminStaffViewModel extends Notifier<AdminStaffState> {
  late final AdminRepository _repository;

  @override
  AdminStaffState build() {
    _repository = ref.watch(adminRepositoryProvider);
    Future.microtask(() => loadInitialData());
    return const AdminStaffState(isLoading: true);
  }

  /// Carga el personal municipal y las cuadrillas para el selector.
  Future<void> loadInitialData() async {
    if (state.isUpdating) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final staffRequest = _repository.getStaffMembers();
    final crewsRequest = _repository.getAvailableCrews();
    final staffResult = await staffRequest;
    final crewsResult = await crewsRequest;

    final staffList = switch (staffResult) {
      Success(data: final list) => list,
      FailureResult() => state.staffMembers,
    };

    final crewList = switch (crewsResult) {
      Success(data: final list) => list,
      FailureResult() => state.crews,
    };

    state = state.copyWith(
      isLoading: false,
      staffMembers: staffList,
      crews: crewList,
      errorMessage: switch ((staffResult, crewsResult)) {
        (FailureResult(failure: final failure), _) => failure.message,
        (_, FailureResult(failure: final failure)) => failure.message,
        _ => null,
      },
    );
  }

  /// Búsqueda privada por coincidencia exacta de correo electrónico.
  Future<void> searchExactEmail(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        clearSearchedUser: true,
        hasSearched: false,
        errorMessage: 'Por favor ingresa un correo electrónico.',
      );
      return;
    }

    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      state = state.copyWith(
        clearSearchedUser: true,
        hasSearched: false,
        errorMessage: 'Ingresa un formato de correo válido (ej. usuario@gmail.com).',
      );
      return;
    }

    state = state.copyWith(isSearching: true, clearError: true, clearSuccess: true);

    final result = await _repository.searchUserByExactEmail(trimmed);

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
    state = state.copyWith(
      clearSearchedUser: true,
      hasSearched: false,
      clearError: true,
      clearSuccess: true,
    );
  }

  /// Asigna una cuadrilla y concede el rol Staff si el usuario aún es ciudadano.
  Future<bool> assignToCrew(UserEntity user, String teamId) async {
    if (state.isUpdating) return false;
    if (!state.crews.any((crew) => crew.id == teamId)) {
      state = state.copyWith(errorMessage: 'Selecciona una cuadrilla válida.');
      return false;
    }
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);

    final result = await _repository.updateUserRole(
      userId: user.id,
      newRole: UserRole.staff,
      teamId: teamId,
    );

    switch (result) {
      case Success():
        final updatedUser = user.copyWith(role: UserRole.staff, teamId: teamId);
        final currentList = List<UserEntity>.from(state.staffMembers);
        final index = currentList.indexWhere((u) => u.id == user.id);
        if (index >= 0) {
          currentList[index] = updatedUser;
        } else {
          currentList.insert(0, updatedUser);
        }

        state = state.copyWith(
          isUpdating: false,
          staffMembers: currentList,
          searchedUser: state.searchedUser?.id == user.id ? updatedUser : null,
          successMessage: 'Cuadrilla actualizada para ${user.name}.',
        );
        return true;
      case FailureResult(failure: final f):
        state = state.copyWith(
          isUpdating: false,
          errorMessage: 'No se pudo asignar la cuadrilla: ${f.message}',
        );
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
