import 'collection_route.dart';

abstract interface class CollectionRouteRepository {
  Stream<List<CollectionRoute>> watchRoutes({String? crewId});

  Stream<CollectionRoute?> watchRoute(String id);

  Future<void> plan(RouteDraft draft, String crewId, RouteWindow window);

  Future<void> reschedule(String id, String crewId, RouteWindow window);

  Future<void> cancel(String id);

  Future<void> start(String id);
  Future<void> skipStop(
    String id,
    String reportId, {
    required String reason,
    required String staffId,
    required String staffName,
  });
}
