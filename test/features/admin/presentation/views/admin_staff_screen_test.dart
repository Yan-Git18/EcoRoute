import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_viewmodel.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_staff_screen.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StaffRepositoryFake implements AdminRepository {
  final crewIds = <String?>[];
  final user = UserEntity(
    id: 'worker',
    name: 'Rosa Silva',
    email: 'rosa@example.com',
    role: UserRole.citizen,
    createdAt: DateTime(2025),
  );

  @override
  Future<Result<List<UserEntity>>> getStaffMembers() async => const Success([]);

  @override
  Future<Result<UserEntity?>> searchUserByExactEmail(String email) async =>
      Success(email == user.email ? user : null);

  @override
  Future<Result<void>> updateUserRole({
    required String userId,
    required UserRole newRole,
    String? teamId,
  }) async {
    expect(userId, user.id);
    expect(newRole, UserRole.staff);
    crewIds.add(teamId);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Promueve a personal de limpieza desde el resultado de búsqueda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _StaffRepositoryFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: AdminStaffScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), repository.user.email);
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asignar como Personal de Limpieza'));
    await tester.pumpAndSettle();

    expect(repository.crewIds, [null]);
    expect(find.text(repository.user.name), findsWidgets);
    expect(find.byTooltip('Cambiar cuadrilla'), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);

    await tester.enterText(find.byType(TextField), 'otra@example.com');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.text('Usuario no encontrado'), findsOneWidget);
    expect(find.textContaining('otra@example.com'), findsWidgets);
  });
}
