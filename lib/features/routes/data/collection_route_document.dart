import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geo/cajamarca_urban_zones.dart';
import '../../citizen/domain/entities/report_entity.dart';
import '../domain/collection_route.dart';

typedef RouteDocument = Map<String, dynamic>;

DocumentReference<RouteDocument> collectionRouteRef(
  FirebaseFirestore firestore,
  String id,
) => firestore.collection('collectionRoutes').doc(id);

DocumentReference<RouteDocument> routeScheduleRef(
  FirebaseFirestore firestore,
  String crewId,
) => firestore.collection('crewRouteSchedules').doc(crewId);

class CollectionRouteDocument {
  static CollectionRoute decode(String id, RouteDocument data) {
    final stops = (data['stops'] as List).cast<RouteDocument>();
    final remaining = data['remainingReportIds'] as List;
    return CollectionRoute(
      id: id,
      name: data['name'] as String,
      zone: CajamarcaZone.fromId(data['zoneId'] as String)!,
      crewId: data['crewId'] as String,
      crewName: data['crewName'] as String,
      vehicle: data['vehicle'] as String,
      window: RouteSchedule.decodeWindow(data),
      stops: List.unmodifiable(stops.map(_decodeStop)),
      completedStops: stops.length - remaining.length,
      skippedStops: Map.unmodifiable(
        (data['skippedStops'] as RouteDocument? ?? {}).cast<String, String>(),
      ),
      status: CollectionRouteStatus.values.byName(data['status'] as String),
      geometry: List.unmodifiable(
        (data['geometry'] as List).cast<GeoPoint>().map(_location),
      ),
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble(),
      durationSeconds: data['durationSeconds'] as int?,
    );
  }

  static CollectionStop _decodeStop(RouteDocument stop) => CollectionStop(
    reportId: stop['reportId'] as String,
    number: stop['number'] as String,
    address: stop['address'] as String,
    location: _location(stop['location'] as GeoPoint),
    priority: ReportPriority.fromString(stop['priority'] as String),
    category: stop['category'] as String? ?? '',
  );

  static LatLng _location(GeoPoint point) =>
      LatLng(point.latitude, point.longitude);

  static GeoPoint _point(LatLng location) =>
      GeoPoint(location.latitude, location.longitude);

  static RouteDocument planningFields(
    RouteDraft draft,
    List<CollectionStop> stops,
  ) {
    final ids = stops.map((stop) => stop.reportId).toList();
    return {
      'name': draft.name.trim(),
      'zoneId': draft.zone.id,
      'reportIds': ids,
      'remainingReportIds': ids,
      'stops': stops
          .map(
            (stop) => {
              'reportId': stop.reportId,
              'number': stop.number,
              'address': stop.address,
              'location': _point(stop.location),
              'priority': stop.priority.toDbString(),
              'category': stop.category,
            },
          )
          .toList(),
      'geometry': draft.geometry.map(_point).toList(),
      'distanceMeters': draft.distanceMeters,
      'durationSeconds': draft.durationSeconds,
      'status': CollectionRouteStatus.planned.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class RouteSchedule {
  RouteSchedule(RouteDocument? data)
    : activeRouteId = data?['activeRouteId'] as String?,
      windows = Map<String, dynamic>.of(
        data?['windows'] as Map<String, dynamic>? ?? {},
      );

  final String? activeRouteId;
  final Map<String, dynamic> windows;

  bool conflicts(String id, RouteWindow window) => windows.entries.any(
    (entry) =>
        entry.key != id &&
        decodeWindow(entry.value as RouteDocument).overlaps(window),
  );

  RouteDocument update(
    String id, {
    required String? active,
    RouteWindow? window,
  }) {
    if (window != null) windows[id] = encodeWindow(window);
    return {
      'activeRouteId': active,
      'transitionRouteId': id,
      'windows': windows,
    };
  }

  static RouteDocument encodeWindow(RouteWindow window) => {
    'scheduledStart': Timestamp.fromDate(window.start),
    'scheduledEnd': Timestamp.fromDate(window.end),
  };

  static RouteWindow decodeWindow(RouteDocument data) => RouteWindow(
    (data['scheduledStart'] as Timestamp).toDate(),
    (data['scheduledEnd'] as Timestamp).toDate(),
  );
}
