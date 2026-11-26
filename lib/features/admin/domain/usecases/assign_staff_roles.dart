import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/admin_repository.dart';

class StaffRoleCandidate {
  const StaffRoleCandidate(this.email, {this.user, required this.status});

  final String email;
  final UserEntity? user;
  final String status;

  bool get canAssign => user?.isCitizen == true && user?.isActive == true;
}

class AssignStaffRoles {
  const AssignStaffRoles(this._repository);

  final AdminRepository _repository;
  static final _separators = RegExp(r'[\s,;]+');
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const _parallelRequests = 8;

  Future<List<StaffRoleCandidate>> lookup(String input) => _inGroups(
    input
        .trim()
        .toLowerCase()
        .split(_separators)
        .where((email) => email.isNotEmpty)
        .toSet()
        .toList(),
    _lookupEmail,
  );

  Future<StaffRoleCandidate> _lookupEmail(String email) async {
    if (!_email.hasMatch(email)) {
      return StaffRoleCandidate(email, status: 'Correo inválido');
    }
    final result = await _repository.searchUserByExactEmail(email);
    return switch (result) {
      Success(data: final user?) => StaffRoleCandidate(
        email,
        user: user,
        status: switch (user) {
          _ when user.isStaff => 'Ya es Personal',
          _ when !user.isCitizen => 'Rol protegido',
          _ when !user.isActive => 'Cuenta inactiva',
          _ => 'Disponible para asignar',
        },
      ),
      Success() => StaffRoleCandidate(email, status: 'Usuario no encontrado'),
      FailureResult() => StaffRoleCandidate(
        email,
        status: 'No se pudo consultar el correo',
      ),
    };
  }

  Future<List<(UserEntity, Result<void>)>> assign(List<UserEntity> users) =>
      _inGroups(
        users,
        (user) async => (
          user,
          await _repository.updateUserRole(
            userId: user.id,
            newRole: UserRole.staff,
          ),
        ),
      );

  Future<List<R>> _inGroups<T, R>(
    List<T> items,
    Future<R> Function(T) operation,
  ) async {
    final results = <R>[];
    for (var start = 0; start < items.length; start += _parallelRequests) {
      results.addAll(
        await Future.wait(
          items.skip(start).take(_parallelRequests).map(operation),
        ),
      );
    }
    return results;
  }
}
