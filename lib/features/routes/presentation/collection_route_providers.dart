import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/services/route_navigation_service.dart';
import '../data/firestore_collection_route_repository.dart';
import '../domain/collection_route.dart';
import '../domain/collection_route_repository.dart';
import '../domain/group_collection_stops.dart';

final collectionRouteRepositoryProvider = Provider<CollectionRouteRepository>((
  ref,
) {
  if (Firebase.apps.isEmpty) {
    throw const ServerException(
      message: 'No hay conexión con la base de datos.',
    );
  }
  return FirestoreCollectionRouteRepository(FirebaseFirestore.instance);
});

final collectionRoutesProvider = StreamProvider.autoDispose
    .family<List<CollectionRoute>, String?>(
      (ref, crewId) => ref
          .watch(collectionRouteRepositoryProvider)
          .watchRoutes(crewId: crewId)
          .withRouteLoadTimeout(),
      retry: (_, _) => null,
    );

final collectionRouteProvider = StreamProvider.autoDispose
    .family<CollectionRoute?, String>(
      (ref, id) => ref
          .watch(collectionRouteRepositoryProvider)
          .watchRoute(id)
          .withRouteLoadTimeout(),
      retry: (_, _) => null,
    );

extension _RouteLoadTimeout<T> on Stream<T> {
  Stream<T> withRouteLoadTimeout() {
    // A live listener may legitimately be idle after its first snapshot.
    var awaitingFirstSnapshot = true;
    return map((value) {
      awaitingFirstSnapshot = false;
      return value;
    }).timeout(
      const Duration(seconds: 12),
      onTimeout: (sink) {
        if (!awaitingFirstSnapshot) return;
        sink.addError(
          TimeoutException('La consulta inicial de rutas agotó el tiempo.'),
        );
        sink.close();
      },
    );
  }
}

final waypointRoutingProvider = Provider<WaypointRoutingService>(
  (ref) => OsrmRouteNavigationServiceImpl(),
);

final groupCollectionStopsProvider = Provider<GroupCollectionStops>(
  (ref) => const GroupCollectionStops(),
);

String collectionRouteError(Object error) {
  if (error is ServerException) return error.message;
  if (error is TimeoutException) {
    return 'Firestore no respondió a tiempo. Revisa tu conexión y vuelve a intentar.';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'La operación no está disponible. Revisa el estado de la ruta y los permisos.',
      'unavailable' =>
        'No se pudo conectar. Revisa tu conexión e intenta nuevamente.',
      _ => 'No se pudo completar la operación de rutas.',
    };
  }
  return 'No se pudo completar la operación de rutas.';
}

String collectionRouteReadError(Object error) {
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Firestore rechazó la consulta de rutas. Verifica los permisos de la cuenta y que las reglas de Rutas estén publicadas en el proyecto de Firebase.';
  }
  return collectionRouteError(error);
}
