import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/repositories/firebase_staff_operations_repository.dart';
import '../../domain/entities/staff_operations.dart';
import '../../domain/repositories/staff_operations_repository.dart';

final staffOperationsRepositoryProvider = Provider<StaffOperationsRepository>(
  (ref) => FirebaseStaffOperationsRepository(
    Firebase.apps.isEmpty ? null : FirebaseFirestore.instance,
  ),
);

final staffTeamIdProvider = StreamProvider.autoDispose<String?>((ref) {
  final user = ref.watch(authViewModelProvider.select((auth) => auth.user));
  if (user == null || !user.isStaff || !user.isActive) {
    return Stream.value(null);
  }
  return ref.watch(staffOperationsRepositoryProvider).watchTeamId(user.id);
});

final _crewProvider = StreamProvider.autoDispose.family<StaffCrew?, String>(
  (ref, teamId) =>
      ref.watch(staffOperationsRepositoryProvider).watchCrew(teamId),
);

final staffCrewProvider = Provider.autoDispose<AsyncValue<StaffCrew?>>((ref) {
  final team = ref.watch(staffTeamIdProvider);
  return switch (team) {
    AsyncData(value: final id?) => ref.watch(_crewProvider(id)),
    AsyncData() => const AsyncData(null),
    AsyncError(:final error, :final stackTrace) => AsyncError(
      error,
      stackTrace,
    ),
    _ => const AsyncLoading(),
  };
});

final staffShiftProvider = StreamProvider.autoDispose
    .family<StaffShift?, String>(
      (ref, uid) =>
          ref.watch(staffOperationsRepositoryProvider).watchShift(uid),
    );

final staffShiftEventsProvider = StreamProvider.autoDispose
    .family<List<StaffShiftEvent>, (String, String)>(
      (ref, key) => ref
          .watch(staffOperationsRepositoryProvider)
          .watchShiftEvents(key.$1, key.$2),
    );

final staffShiftClockProvider = StreamProvider.autoDispose<DateTime>((
  ref,
) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

String staffCrewName(AsyncValue<StaffCrew?> crew) => switch (crew) {
  AsyncData(value: final assignment?) =>
    assignment.name ?? 'Cuadrilla sin nombre',
  AsyncData() => 'Sin cuadrilla asignada',
  AsyncError() => 'Cuadrilla no disponible',
  _ => 'Cargando cuadrilla…',
};
