import 'dart:async';

import 'package:ecoroute/core/router/route_names.dart';
import 'package:ecoroute/core/errors/failures.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_viewmodel.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_staff_screen.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _StaffRepositoryFake implements AdminRepository {
  final crewIds = <String?>[];
  final assignedIds = <String>[];
  final otherUsers = <UserEntity>[];
  final failedIds = <String>{};
  Completer<Result<UserEntity?>>? pendingSearch;
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
      pendingSearch?.future ??
      Success(
        [
          user,
          ...otherUsers,
        ].where((candidate) => candidate.email == email).firstOrNull,
      );

  @override
  Future<Result<void>> updateUserRole({
    required String userId,
    required UserRole newRole,
    String? teamId,
  }) async {
    expect(
      [user, ...otherUsers].map((candidate) => candidate.id),
      contains(userId),
    );
    expect(newRole, UserRole.staff);
    if (failedIds.contains(userId)) {
      return const FailureResult(ServerFailure(message: 'No se pudo guardar'));
    }
    assignedIds.add(userId);
    crewIds.add(teamId);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'Asigna varios correos y permite reintentar solo el cambio fallido',
    (tester) async {
      final repository = _StaffRepositoryFake();
      repository.otherUsers.addAll([
        repository.user.copyWith(
          id: 'second',
          email: 'luis@example.com',
          name: 'Luis Torres',
        ),
        repository.user.copyWith(
          id: 'admin',
          email: 'admin@example.com',
          role: UserRole.admin,
          name: 'Ana Reyes',
        ),
      ]);
      repository.failedIds.add('second');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: AdminStaffScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asignar varios usuarios'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'ROSA@example.com, rosa@example.com\nluis@example.com; admin@example.com; nadie@example.com',
      );
      await tester.pump();
      await tester.tap(find.text('Buscar y revisar'));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      expect(find.textContaining('Rol protegido'), findsOneWidget);
      expect(find.text('Usuario no encontrado'), findsOneWidget);
      await tester.tap(find.text('Asignar rol a 2'));
      await tester.pumpAndSettle();
      expect(repository.assignedIds, ['worker']);
      expect(find.textContaining('No se pudo guardar'), findsOneWidget);
      repository.failedIds.clear();
      await tester.tap(find.text('Asignar rol a 1'));
      await tester.pumpAndSettle();
      expect(repository.assignedIds, ['worker', 'second']);
    },
  );

  testWidgets(
    'Conserva la búsqueda al volver de un detalle y la limpia al salir de Personal',
    (tester) async {
      final repository = _StaffRepositoryFake();
      final router = GoRouter(
        initialLocation: RouteNames.adminStaff,
        routes: [
          GoRoute(
            path: RouteNames.adminStaff,
            builder: (_, _) => const AdminStaffScreen(),
          ),
          GoRoute(
            path: RouteNames.adminDashboard,
            builder: (_, _) => const Scaffold(body: Text('Inicio')),
          ),
          GoRoute(
            path: '/detalle',
            builder: (_, _) => const Scaffold(body: Text('Detalle de persona')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final field = find.byType(TextField);
      String? query() => tester.widget<TextField>(field).controller?.text;

      Future<void> search(String email) async {
        await tester.enterText(field, email);
        await tester.tap(find.text('Buscar'));
        await tester.pump();
      }

      for (final (email, result) in [
        (repository.user.email, repository.user.name),
        ('otra@example.com', 'Usuario no encontrado'),
      ]) {
        await search(email);
        await tester.pumpAndSettle();
        expect(find.text(result), findsOneWidget);

        router.push<void>('/detalle');
        await tester.pumpAndSettle();
        expect(find.text('Detalle de persona'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        expect(query(), email);
        expect(find.text(result), findsOneWidget);

        router.go(RouteNames.adminDashboard);
        await tester.pumpAndSettle();
        router.go(RouteNames.adminStaff);
        await tester.pumpAndSettle();
        expect(query(), isEmpty);
        expect(find.text(result), findsNothing);
      }

      final pending = Completer<Result<UserEntity?>>();
      repository.pendingSearch = pending;
      await search(repository.user.email);
      router.go(RouteNames.adminDashboard);
      await tester.pumpAndSettle();
      router.go(RouteNames.adminStaff);
      await tester.pumpAndSettle();

      pending.complete(Success(repository.user));
      await tester.pumpAndSettle();
      expect(query(), isEmpty);
      expect(find.text(repository.user.name), findsNothing);
    },
  );

  testWidgets(
    'Promueve a personal de limpieza desde el resultado de búsqueda',
    (tester) async {
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
    },
  );
}
