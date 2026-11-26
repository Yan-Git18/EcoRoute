import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/exceptions.dart';
import '../domain/collection_route.dart';
import 'collection_route_document.dart';

typedef RelatedReportWrite = void Function(Transaction transaction);

class RouteStopTransaction {
  const RouteStopTransaction(this._firestore, this._reportId);

  final FirebaseFirestore _firestore;
  final String _reportId;

  Future<RouteDocument> start(
    Transaction transaction,
    RouteDocument report,
  ) async {
    final routeId = report['collectionRouteId'] as String?;
    if (routeId == null) return {};
    final route = await _currentRoute(transaction, routeId);
    return {
      'assignedToTeamId': route['crewId'],
      'assignedToTeamName': route['crewName'],
      'assignedVehicle': route['vehicle'],
    };
  }

  Future<RelatedReportWrite?> complete(
    Transaction transaction,
    RouteDocument report, {
    String? skippedReason,
  }) async {
    final routeId = report['collectionRouteId'] as String?;
    if (routeId == null) return null;
    final route = await _currentRoute(transaction, routeId);
    final remaining = (route['remainingReportIds'] as List).skip(1).toList();
    final completed = remaining.isEmpty;
    final scheduleRef = routeScheduleRef(_firestore, route['crewId'] as String);
    final schedule = completed
        ? RouteSchedule((await transaction.get(scheduleRef)).data())
        : null;
    schedule?.windows.remove(routeId);
    return (transaction) {
      transaction.update(collectionRouteRef(_firestore, routeId), {
        'remainingReportIds': remaining,
        if (skippedReason != null)
          'skippedStops': {
            ...(route['skippedStops'] as RouteDocument? ?? {}),
            _reportId: skippedReason,
          },
        if (completed) 'status': CollectionRouteStatus.completed.name,
        if (completed) 'finishedAt': FieldValue.serverTimestamp(),
      });
      if (schedule != null) {
        transaction.set(scheduleRef, schedule.update(routeId, active: null));
      }
    };
  }

  Future<RouteDocument> _currentRoute(
    Transaction transaction,
    String id,
  ) async {
    final route = (await transaction.get(
      collectionRouteRef(_firestore, id),
    )).data();
    if (route == null ||
        route['status'] != CollectionRouteStatus.inProgress.name ||
        (route['remainingReportIds'] as List).firstOrNull != _reportId) {
      throw const ServerException(
        message:
            'Esta parada aún no está disponible. Revisa el orden de la ruta.',
      );
    }
    return route;
  }
}
