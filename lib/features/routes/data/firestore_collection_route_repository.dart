import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/geo/cajamarca_urban_zones.dart';
import '../../../core/services/report_status_transaction.dart';
import '../../admin/data/models/municipal_crew_dto.dart';
import '../../admin/domain/entities/municipal_crew_entity.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../citizen/data/models/report_dto.dart';
import '../domain/collection_route.dart';
import '../domain/collection_route_repository.dart';
import 'collection_route_document.dart';
import 'route_stop_transaction.dart';

class FirestoreCollectionRouteRepository implements CollectionRouteRepository {
  const FirestoreCollectionRouteRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<RouteDocument> _route(String id) =>
      collectionRouteRef(_firestore, id);

  DocumentReference<RouteDocument> _schedule(String crewId) =>
      routeScheduleRef(_firestore, crewId);

  DocumentReference<RouteDocument> _report(String id) =>
      _firestore.collection('reports').doc(id);

  @override
  Stream<List<CollectionRoute>> watchRoutes({String? crewId}) {
    Query<RouteDocument> query = _firestore.collection('collectionRoutes');
    if (crewId != null) query = query.where('crewId', isEqualTo: crewId);
    return query
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => CollectionRouteDocument.decode(doc.id, doc.data()),
                  )
                  .toList()
                ..sort((a, b) => a.window.start.compareTo(b.window.start)),
        );
  }

  @override
  Stream<CollectionRoute?> watchRoute(String id) => _route(id)
      .snapshots(includeMetadataChanges: true)
      .where((snapshot) => !snapshot.metadata.isFromCache)
      .map(
        (snapshot) => switch (snapshot.data()) {
          final data? => CollectionRouteDocument.decode(id, data),
          null => null,
        },
      );

  @override
  Future<void> plan(RouteDraft draft, String crewId, RouteWindow window) {
    _validateWindow(window);

    final ids = draft.stops.map((stop) => stop.reportId).toSet();
    if (draft.name.trim().isEmpty ||
        draft.name.trim().length > 80 ||
        ids.isEmpty ||
        ids.length > CollectionRoute.maxStops ||
        ids.length != draft.stops.length) {
      throw const ServerException(
        message: 'Revisa el nombre y las paradas de la ruta.',
      );
    }

    final route = _firestore.collection('collectionRoutes').doc();
    return _firestore.runTransaction((transaction) async {
      final schedule = await _availableSchedule(
        transaction,
        crewId,
        route.id,
        window,
      );
      final assignment = await _crewAssignment(transaction, crewId);
      final confirmedStops = <CollectionStop>[];
      for (final stop in draft.stops) {
        final data = (await transaction.get(_report(stop.reportId))).data();
        confirmedStops.add(_confirmStop(data, draft.zone, stop));
      }

      transaction.set(route, {
        ...CollectionRouteDocument.planningFields(draft, confirmedStops),
        ...assignment,
        ...RouteSchedule.encodeWindow(window),
      });
      transaction.set(
        _schedule(crewId),
        schedule.update(
          route.id,
          active: schedule.activeRouteId,
          window: window,
        ),
      );
      for (final id in ids) {
        transaction.update(_report(id), {'collectionRouteId': route.id});
      }
    });
  }

  static CollectionStop _confirmStop(
    RouteDocument? data,
    CajamarcaZone zone,
    CollectionStop stop,
  ) {
    if (data != null &&
        const ['pending', 'pendiente'].contains(data['status']) &&
        data['collectionRouteId'] == null &&
        _isUnassigned(data)) {
      final current = CollectionStop.fromReport(
        ReportDto.fromMap(data, stop.reportId).toDomain(),
      );
      final location = current.location;
      if (location == stop.location &&
          CajamarcaUrbanZones.zoneAt(location.latitude, location.longitude) ==
              zone) {
        return current;
      }
    }
    throw ServerException(
      message:
          'El reporte ${stop.number} cambió. Actualiza los reportes y revisa la propuesta.',
    );
  }

  static bool _isUnassigned(RouteDocument data) =>
      [null, ''].contains(data['assignedToTeamId']) &&
      [null, ''].contains(data['assignedStaffId']) &&
      ((data['assignedStaffIds'] as List?)?.isEmpty ?? true);

  @override
  Future<void> reschedule(String id, String crewId, RouteWindow window) {
    _validateWindow(window);
    return _firestore.runTransaction((transaction) async {
      final data = await _readRoute(transaction, id);
      if (data['status'] != CollectionRouteStatus.planned.name) {
        throw const ServerException(
          message: 'Solo se pueden editar las rutas planificadas.',
        );
      }
      final previousCrewId = data['crewId'] as String;
      final schedule = await _availableSchedule(
        transaction,
        crewId,
        id,
        window,
      );
      final assignment = await _crewAssignment(transaction, crewId);
      if (previousCrewId != crewId) {
        final previous = await _readSchedule(transaction, previousCrewId);
        previous.windows.remove(id);
        transaction.set(
          _schedule(previousCrewId),
          previous.update(id, active: previous.activeRouteId),
        );
      }
      transaction.set(
        _schedule(crewId),
        schedule.update(id, active: schedule.activeRouteId, window: window),
      );
      transaction.update(_route(id), {
        ...assignment,
        ...RouteSchedule.encodeWindow(window),
      });
    });
  }

  @override
  Future<void> start(String id) => _firestore.runTransaction((
    transaction,
  ) async {
    final data = await _readRoute(transaction, id);
    final crewId = data['crewId'] as String;
    final schedule = await _readSchedule(transaction, crewId);
    if (data['status'] == CollectionRouteStatus.inProgress.name &&
        schedule.activeRouteId == id) {
      return;
    }

    if (data['status'] != CollectionRouteStatus.planned.name ||
        !schedule.windows.containsKey(id)) {
      throw const ServerException(message: 'Esta ruta ya no está planificada.');
    }
    if (DateTime.now().isBefore(RouteSchedule.decodeWindow(data).start)) {
      throw const ServerException(
        message: 'La hora programada de esta ruta aún no ha llegado.',
      );
    }

    final crew = (await transaction.get(
      _firestore.collection('crews').doc(crewId),
    )).data();
    if (schedule.activeRouteId != null ||
        crew == null ||
        !MunicipalCrewDto.fromMap(crew, crewId).toDomain().canDispatch) {
      throw const ServerException(
        message: 'El equipo tiene trabajo en curso o no está disponible.',
      );
    }
    transaction.set(_schedule(crewId), schedule.update(id, active: id));
    transaction.update(_route(id), {
      'status': CollectionRouteStatus.inProgress.name,
      'startedAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Future<void> skipStop(
    String id,
    String reportId, {
    required String reason,
    required String staffId,
    required String staffName,
  }) async {
    final comment = reason.trim();
    if (comment.isEmpty || comment.length > 300) {
      throw const ServerException(
        message: 'Escribe un motivo de hasta 300 caracteres.',
      );
    }
    final stop = RouteStopTransaction(_firestore, reportId);
    await writeReportStatus(
      report: _report(reportId),
      changes: {
        'status': 'pending',
        for (final key in [
          'collectionRouteId',
          'assignedStaffId',
          'assignedStaffName',
          'assignedToTeamId',
          'assignedToTeamName',
          'assignedVehicle',
        ])
          key: FieldValue.delete(),
      },
      audit: ReportAudit(
        userId: staffId,
        userName: staffName,
        role: 'staff',
        comment: comment,
      ),
      stageRelatedWrites: (transaction, report) {
        if (report['collectionRouteId'] != id ||
            !const [
              'pending',
              'pendiente',
              'in_progress',
              'en proceso',
            ].contains(report['status'])) {
          throw const ServerException(
            message: 'La parada ya no está disponible.',
          );
        }
        return stop.complete(transaction, report, skippedReason: comment);
      },
    );
  }

  @override
  Future<void> cancel(String id) => _firestore.runTransaction((
    transaction,
  ) async {
    final data = await _readRoute(transaction, id);
    if (data['status'] == CollectionRouteStatus.cancelled.name) return;
    if (data['status'] == CollectionRouteStatus.completed.name) {
      throw const ServerException(message: 'La ruta ya finalizó.');
    }

    final crewId = data['crewId'] as String;
    final schedule = await _readSchedule(transaction, crewId);
    final remaining = (data['remainingReportIds'] as List).cast<String>();
    for (final reportId in remaining) {
      final report = (await transaction.get(_report(reportId))).data();
      if (report?['collectionRouteId'] != id ||
          !const ['pending', 'pendiente'].contains(report?['status'])) {
        throw const ServerException(
          message: 'Finaliza la parada en atención antes de cancelar la ruta.',
        );
      }
    }
    schedule.windows.remove(id);
    transaction.set(
      _schedule(crewId),
      schedule.update(
        id,
        active: schedule.activeRouteId == id ? null : schedule.activeRouteId,
      ),
    );
    transaction.update(_route(id), {
      'status': CollectionRouteStatus.cancelled.name,
      'finishedAt': FieldValue.serverTimestamp(),
    });
    for (final reportId in remaining) {
      transaction.update(_report(reportId), {
        'collectionRouteId': FieldValue.delete(),
      });
    }
  });

  Future<RouteDocument> _readRoute(Transaction transaction, String id) async {
    final data = (await transaction.get(_route(id))).data();
    if (data == null) {
      throw const ServerException(message: 'La ruta ya no existe.');
    }
    return data;
  }

  Future<RouteSchedule> _readSchedule(
    Transaction transaction,
    String crewId,
  ) async => RouteSchedule((await transaction.get(_schedule(crewId))).data());

  Future<RouteSchedule> _availableSchedule(
    Transaction transaction,
    String crewId,
    String id,
    RouteWindow window,
  ) async {
    final schedule = await _readSchedule(transaction, crewId);
    if (schedule.conflicts(id, window)) {
      throw const ServerException(
        message: 'El equipo tiene otra ruta programada en ese horario.',
      );
    }
    if (schedule.activeRouteId != null &&
        !window.start.isAfter(DateTime.now())) {
      throw const ServerException(
        message:
            'El equipo está ejecutando una ruta. Elige un horario posterior.',
      );
    }
    return schedule;
  }

  Future<RouteDocument> _crewAssignment(
    Transaction transaction,
    String id,
  ) async {
    final data = (await transaction.get(
      _firestore.collection('crews').doc(id),
    )).data();
    final crew = data == null
        ? null
        : MunicipalCrewDto.fromMap(data, id).toDomain();
    final leaderId = crew?.effectiveLeaderId;
    if (crew == null ||
        crew.vehicleOnly ||
        !crew.isAvailable ||
        crew.status == MunicipalCrewStatus.maintenance ||
        leaderId == null) {
      throw const ServerException(
        message: 'El equipo requiere un líder y un camión disponible.',
      );
    }
    final leader = (await transaction.get(
      _firestore.collection('users').doc(leaderId),
    )).data();
    if (leader == null ||
        leader['teamId'] != id ||
        leader['isActive'] == false ||
        UserRole.fromString(leader['role'] as String? ?? '') !=
            UserRole.staff) {
      throw const ServerException(
        message: 'El líder del equipo ya no está disponible.',
      );
    }
    final truck = crew.vehicleId == null
        ? data
        : (await transaction.get(
            _firestore.collection('vehicles').doc(crew.vehicleId),
          )).data();
    if (truck == null ||
        (crew.vehicleId != null &&
            (truck['assignedCrewId'] != id ||
                truck['status'] != 'available' ||
                truck['isAvailable'] == false)) ||
        (truck['vehiclePlate'] as String?)?.trim().isNotEmpty != true) {
      throw const ServerException(
        message: 'El vehículo del equipo ya no está disponible.',
      );
    }

    return {
      'crewId': id,
      'crewName': crew.name,
      'vehicle': '${truck['vehicleCode']} · ${truck['vehiclePlate']}',
    };
  }

  static void _validateWindow(RouteWindow window) {
    if (!window.isValid || !window.end.isAfter(DateTime.now())) {
      throw const ServerException(
        message: 'Selecciona un intervalo vigente de inicio y fin.',
      );
    }
  }
}
