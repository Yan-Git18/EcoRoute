import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:latlong2/latlong.dart';

import '../../../../core/services/route_navigation_service.dart';
import '../../../routes/domain/collection_route.dart';
import '../../../routes/presentation/collection_route_providers.dart';
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

final staffCanManageTaskProvider = Provider.autoDispose.family<bool, String?>((
  ref,
  teamId,
) {
  if (teamId == null) return true;
  final uid = ref.watch(authViewModelProvider.select((auth) => auth.user?.id));
  final crew = ref.watch(staffCrewProvider).asData?.value;
  return uid != null && crew?.id == teamId && crew?.leaderId == uid;
});

final staffTeamTaskChangesProvider = StreamProvider.autoDispose<int>((ref) {
  final teamId = ref.watch(staffTeamIdProvider).asData?.value;
  if (teamId == null) return const Stream.empty();
  return ref
      .watch(staffOperationsRepositoryProvider)
      .watchTeamTaskChanges(teamId);
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

final staffCollectionRoutesProvider =
    Provider.autoDispose<AsyncValue<List<CollectionRoute>>>((ref) {
      return ref
          .watch(staffTeamIdProvider)
          .when(
            data: (id) => id == null
                ? const AsyncData(<CollectionRoute>[])
                : ref.watch(collectionRoutesProvider(id)),
            error: AsyncError.new,
            loading: () => const AsyncLoading(),
          );
    });

final staffCurrentCollectionRouteProvider =
    Provider.autoDispose<CollectionRoute?>((ref) {
      final routes = ref.watch(staffCollectionRoutesProvider).asData?.value;
      if (routes == null) return null;
      return routes
              .where(
                (route) => route.status == CollectionRouteStatus.inProgress,
              )
              .firstOrNull ??
          routes
              .where((route) => route.status == CollectionRouteStatus.planned)
              .firstOrNull;
    });

final staffCollectionLegProvider = FutureProvider.autoDispose
    .family<RouteInfoResult, (LatLng, LatLng)>((ref, points) {
      final (origin, destination) = points;
      return ref
          .watch(routeNavigationServiceProvider)
          .calculateOptimalRoute(
            originLat: origin.latitude,
            originLng: origin.longitude,
            destLat: destination.latitude,
            destLng: destination.longitude,
          );
    });
