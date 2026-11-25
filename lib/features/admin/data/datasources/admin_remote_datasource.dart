import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/report_status_transaction.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../citizen/data/models/report_dto.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/admin_report_page.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../models/municipal_crew_dto.dart';

/// Contrato para la fuente remota de datos del administrador municipal.
abstract class AdminRemoteDataSource {
  Future<AdminReportPage<ReportDto>> getReportsPage({AdminReportCursor? after});
  Future<AdminReportTotals> getReportTotals();
  Future<List<MunicipalCrewDto>> getAvailableCrews();
  Future<List<ReportDto>> getCrewActiveReports(String crewId);
  Future<MunicipalCrewDto> createCrew(MunicipalCrewEntity crew);
  Future<void> updateCrew(MunicipalCrewEntity crew);
  Future<void> deleteCrew(String crewId);
  Future<ReportDto> assignReportToStaff({
    required String reportId,
    required List<String> staffIds,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  });
  Future<Set<String>> getBusyStaffIds();

  Future<ReportDto> assignReportToCrew({
    required String reportId,
    required MunicipalCrewEntity crew,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  });
  Future<ReportDto> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  });

  /// Obtiene únicamente los usuarios con rol de personal (staff).
  /// Protege la privacidad evitando consultar cuentas ciudadanas.
  Future<List<UserEntity>> getStaffMembers();

  /// Búsqueda estricta por correo exacto para no filtrar correos de ciudadanos.
  Future<UserEntity?> searchUserByExactEmail(String email);

  /// Asigna o revierte el rol de un usuario en Cloud Firestore.
  Future<void> updateUserRole({
    required String userId,
    required UserRole newRole,
  });
}

class _FirestoreReportCursor implements AdminReportCursor {
  const _FirestoreReportCursor(this.document);

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
}

/// Implementación concreta con Cloud Firestore.
class FirebaseAdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final FirebaseFirestore? _customFirestore;

  FirebaseAdminRemoteDataSourceImpl({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  static const _server = GetOptions(source: Source.server);
  static const _openStatuses = [
    'assigned',
    'asignado',
    'in_progress',
    'en proceso',
  ];
  CollectionReference<Map<String, dynamic>> get _crews =>
      _firestore.collection('crews');
  CollectionReference<Map<String, dynamic>> get _vehicles =>
      _firestore.collection('vehicles');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');
  static const _readTimeout = Duration(seconds: 12);

  @override
  Future<AdminReportPage<ReportDto>> getReportsPage({
    AdminReportCursor? after,
  }) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada.');
    }

    try {
      var query = _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true);
      if (after != null) {
        query = query.startAfterDocument(
          (after as _FirestoreReportCursor).document,
        );
      }
      final snapshot = await query
          .limit(AdminReportPage.pageSize + 1)
          .get(const GetOptions(source: Source.server))
          .timeout(_readTimeout);
      final page = snapshot.docs.take(AdminReportPage.pageSize).toList();
      return AdminReportPage(
        page.map((doc) => ReportDto.fromMap(doc.data(), doc.id)).toList(),
        nextCursor: snapshot.docs.length > AdminReportPage.pageSize
            ? _FirestoreReportCursor(page.last)
            : null,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'No se pudieron consultar los reportes.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(
        message: 'Error al consultar reportes en Firestore: $e',
      );
    }
  }

  @override
  Future<AdminReportTotals> getReportTotals() async {
    final reports = _firestore.collection('reports');
    Future<int> countReports(Query<Map<String, dynamic>> query) async =>
        (await query.count().get().timeout(_readTimeout)).count!;

    Future<int> countStatus(ReportStatus status) => countReports(
      reports.where(
        'status',
        whereIn: [
          status.toDbString(),
          status.toDbString().toUpperCase(),
          status.label.toLowerCase(),
          status.label,
          status.label.toUpperCase(),
        ],
      ),
    );

    final (total, assigned, inProgress, resolved, cancelled) = await (
      countReports(reports),
      countStatus(ReportStatus.assigned),
      countStatus(ReportStatus.inProgress),
      countStatus(ReportStatus.resolved),
      countStatus(ReportStatus.cancelled),
    ).wait;
    return (
      total: total,
      pending: (total - assigned - inProgress - resolved - cancelled).clamp(
        0,
        total,
      ),
      assigned: assigned,
      inProgress: inProgress,
      resolved: resolved,
    );
  }

  @override
  Future<List<MunicipalCrewDto>> getAvailableCrews() async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada.');
    }

    try {
      final (crews, vehicles) = await (
        _crews.get(_server).timeout(_readTimeout),
        _vehicles.get(_server).timeout(_readTimeout),
      ).wait;
      final trucks = {for (final doc in vehicles.docs) doc.id: doc.data()};
      return [
        for (final doc in crews.docs)
          if (doc.data()['vehicleOnly'] != true)
            MunicipalCrewDto.fromMap(
              _withVehicle(doc.id, doc.data(), trucks),
              doc.id,
            ),
        for (final entry in trucks.entries)
          MunicipalCrewDto.fromMap(
            {...entry.value, 'vehicleOnly': true},
            entry.key,
          ),
      ];
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'No se pudieron consultar las cuadrillas.',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(
        message: 'Error al consultar cuadrillas en Firestore: $e',
      );
    }
  }

  Map<String, dynamic> _withVehicle(
    String crewId,
    Map<String, dynamic> crew,
    Map<String, Map<String, dynamic>> documents,
  ) {
    final vehicleId = crew['vehicleId'];
    if (vehicleId == null) return crew;
    final truck = documents[vehicleId];
    if (truck == null) return {...crew, 'isAvailable': false};
    return {
      ...crew,
      for (final field in ['vehicleCode', 'vehiclePlate', 'vehicleType'])
        field: truck[field],
      if (!_vehicleAvailable(truck, crewId))
        'isAvailable': false,
    };
  }

  bool _vehicleAvailable(Map<String, dynamic> truck, String? crewId) =>
      (truck['assignedCrewId'] == null || truck['assignedCrewId'] == crewId) &&
      truck['status'] == 'available' &&
      truck['isAvailable'] != false;

  @override
  Future<MunicipalCrewDto> createCrew(MunicipalCrewEntity crew) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada.');
    }
    final collection = crew.vehicleOnly ? _vehicles : _crews;
    final ref = crew.id.isEmpty ? collection.doc() : collection.doc(crew.id);
    final dto = MunicipalCrewDto.fromDomain(crew.copyWith(id: ref.id));
    if (crew.vehicleOnly) {
      await ref.set(_vehicleFields(dto));
      return dto;
    }
    return _saveTeam(ref, crew.copyWith(id: ref.id), creating: true);
  }

  Map<String, dynamic> _vehicleFields(MunicipalCrewDto dto) => dto.toMap()
    ..remove('vehicleOnly')
    ..remove('vehicleId')
    ..remove('memberIds')
    ..remove('crewMembersCount')
    ..remove('activeTasksCount')
    ..remove('assignedCrewId');

  @override
  Future<void> updateCrew(MunicipalCrewEntity crew) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada.');
    }
    if (crew.vehicleOnly) {
      final fields = _vehicleFields(MunicipalCrewDto.fromDomain(crew))
        ..remove('createdAt');
      await _vehicles.doc(crew.id).update(fields);
      return;
    }
    final ref = _crews.doc(crew.id);
    if (crew.memberIds != null) {
      await _saveTeam(ref, crew);
      return;
    }
    final fields = MunicipalCrewDto.fromDomain(crew).toMap()
      ..remove('createdAt')
      ..remove('activeTasksCount')
      ..remove('assignedCrewId');
    await ref.update(fields);
  }

  Future<List<String>> _legacyMembers(String crewId) async {
    final result = await _users
        .where('teamId', isEqualTo: crewId)
        .get(_server)
        .timeout(_readTimeout);
    return result.docs.map((doc) => doc.id).toList();
  }

  Future<MunicipalCrewDto> _saveTeam(
    DocumentReference<Map<String, dynamic>> ref,
    MunicipalCrewEntity crew, {
    bool creating = false,
  }) async {
    final roster = crew.memberIds ?? const <String>[];
    if (roster.length != crew.crewMembersCount ||
        roster.toSet().length != roster.length) {
      throw const ServerException(
        message: 'Selecciona entre 2 y 5 integrantes para el equipo.',
      );
    }
    final legacy = creating ? const <String>[] : await _legacyMembers(ref.id);
    return _firestore.runTransaction((transaction) async {
      final previous = (await transaction.get(ref)).data();
      if (creating == (previous != null) || previous?['vehicleOnly'] == true) {
        throw const ServerException(
          message: 'El registro del equipo cambió. Actualiza la lista.',
        );
      }
      final before =
          (previous?['memberIds'] as List?)?.cast<String>() ?? legacy;
      final storedCount = previous?['memberCount'];
      if (storedCount != null && storedCount != before.length) {
        throw const ServerException(
          message: 'El personal del equipo cambió. Actualiza la lista.',
        );
      }
      final oldVehicle = previous?['vehicleId'] as String?;
      final vehicleId = crew.vehicleId;
      final rosterChanged =
          before.length != roster.length || !before.every(roster.contains);
      final vehicleChanged = oldVehicle != vehicleId;
      final validSize = MunicipalCrewEntity.isValidMemberCount(roster.length);
      if (!validSize && (creating || rosterChanged || vehicleChanged)) {
        throw const ServerException(
          message: 'Selecciona entre 2 y 5 integrantes para el equipo.',
        );
      }
      if (previous != null &&
          crew.updatedAt != null &&
          MunicipalCrewDto.fromMap(previous, ref.id).updatedAt != crew.updatedAt) {
        throw const ServerException(
          message: 'Otra persona actualizó el equipo. Vuelve a abrirlo para editar los datos actuales.',
        );
      }
      final openReports = previous?['openReportCount'];
      if (previous != null &&
          openReports != 0 &&
          (rosterChanged || vehicleChanged)) {
        throw ServerException(
          message: openReports == null
              ? 'El equipo requiere actualizar sus datos anteriores antes de cambiar sus recursos.'
              : 'El equipo tiene un reporte activo. Finalízalo para cambiar sus recursos.',
        );
      }
      final recordRoster = creating ||
          rosterChanged ||
          (vehicleChanged && previous?['memberIds'] == null);
      if (!recordRoster && !vehicleChanged && previous != null) {
        final fields = {
          'name': crew.name,
          'zone': crew.zone,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        transaction.update(ref, fields);
        return MunicipalCrewDto.fromMap({...previous, ...fields}, ref.id);
      }
      if (vehicleId == null &&
          (creating || vehicleChanged)) {
        throw const ServerException(
          message: 'Selecciona un camión disponible.',
        );
      }

      final truckRef = vehicleId == null ? null : _vehicles.doc(vehicleId);
      final truck = truckRef == null
          ? null
          : (await transaction.get(truckRef)).data();
      if (truckRef != null &&
          (truck == null ||
              (oldVehicle == vehicleId
                  ? truck['assignedCrewId'] != ref.id
                  : !_vehicleAvailable(truck, ref.id)))) {
        throw const ServerException(
          message: 'El camión seleccionado ya no está disponible.',
        );
      }

      final profiles = <String, UserEntity>{};
      for (final uid in {...before, ...roster}) {
        final data = (await transaction.get(_users.doc(uid))).data();
        if (data == null) {
          throw const ServerException(
            message: 'No se encontró a uno de los integrantes.',
          );
        }
        final profile = UserDto.fromMap(data, uid).toDomain();
        final currentTeam = profile.teamId;
        if (before.contains(uid) && currentTeam != ref.id ||
            roster.contains(uid) &&
                (!profile.isStaff ||
                    (recordRoster && !profile.isActive) ||
                    (!before.contains(uid) &&
                        currentTeam?.isNotEmpty == true))) {
          throw ServerException(
            message: '${profile.name} ya no está disponible para este equipo.',
          );
        }
        if (!before.contains(uid) && roster.contains(uid)) {
          await _requireFreeStaff(transaction, uid);
        }
        profiles[uid] = profile;
      }

      final oldTruck = vehicleChanged
          ? await _vehicleToRelease(transaction, ref, previous)
          : null;
      final leader = previous?['memberIds'] != null
          ? before.where(roster.contains).firstOrNull ?? roster.first
          : roster.first;
      final orderedRoster = [leader, ...roster.where((uid) => uid != leader)];
      final dto = MunicipalCrewDto.fromDomain(
        crew.copyWith(
          leadStaffName: profiles[leader]!.name,
          memberIds: orderedRoster,
          vehicleCode: truck?['vehicleCode'] as String?,
          vehiclePlate: truck?['vehiclePlate'] as String?,
          vehicleType: truck?['vehicleType'] as String?,
          activeTasksCount: (previous?['openReportCount'] as int?) ?? 0,
        ),
      );
      if (creating) {
        final fields = dto.toMap()
          ..remove('activeTasksCount')
          ..remove('location')
          ..remove('latitude')
          ..remove('longitude');
        transaction.set(ref, {
          ...fields,
          'openReportCount': 0,
          'memberCount': roster.length,
        });
      } else {
        transaction.update(ref, {
          'name': crew.name,
          'zone': crew.zone,
          'updatedAt': FieldValue.serverTimestamp(),
          if (recordRoster) ...{
            'leadStaffName': dto.leadStaffName,
            'memberIds': orderedRoster,
            'memberCount': roster.length,
            'crewMembersCount': roster.length,
          },
          if (vehicleChanged) ...{
            'vehicleId': vehicleId,
            'vehicleCode': dto.vehicleCode,
            'vehiclePlate': dto.vehiclePlate,
            'vehicleType': dto.vehicleType,
          },
        });
      }
      for (final uid in {...before, ...roster}) {
        if (before.contains(uid) == roster.contains(uid)) continue;
        transaction.update(_users.doc(uid), {
          'teamId': roster.contains(uid) ? ref.id : FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (truckRef != null && oldVehicle != vehicleId) {
        _releaseVehicle(transaction, oldTruck, previous);
        transaction.update(truckRef, {'assignedCrewId': ref.id});
      }
      return dto;
    });
  }

  Future<DocumentReference<Map<String, dynamic>>?> _vehicleToRelease(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> crew,
    Map<String, dynamic>? data,
  ) async {
    if (data == null || data['vehicleOnly'] == true) return null;
    final vehicleId = data['vehicleId'] as String?;
    if (vehicleId != null) {
      final truck = _vehicles.doc(vehicleId);
      final existing = (await transaction.get(truck)).data();
      return existing?['assignedCrewId'] == crew.id ? truck : null;
    }
    final plate = data['vehiclePlate'];
    if (plate is! String || plate.trim().isEmpty) return null;
    final truck = _vehicles.doc('vehicle-${crew.id}');
    if ((await transaction.get(truck)).exists) return null;
    return truck;
  }

  void _releaseVehicle(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>>? truck,
    Map<String, dynamic>? data,
  ) {
    if (truck == null || data == null) return;
    if (data['vehicleId'] != null) {
      transaction.update(truck, {
        'assignedCrewId': FieldValue.delete(),
      });
    } else {
      transaction.set(truck, {
        ..._vehicleFields(MunicipalCrewDto.fromMap(data, truck.id)),
        'name': data['vehicleCode'] ?? data['vehiclePlate'],
      });
    }
  }

  @override
  Future<void> deleteCrew(String crewId) async {
    final crew = _crews.doc(crewId);
    final previous = (await crew.get(_server).timeout(_readTimeout)).data();
    if (previous == null) return;
    final memberCount = previous['memberCount'];
    if (previous['openReportCount'] == 0 &&
        previous['vehicleOnly'] != true &&
        previous['memberIds'] == null &&
        memberCount is int &&
        memberCount > 0) {
      await _recordLegacyRoster(crew);
    }
    await _firestore.runTransaction((transaction) async {
      final data = (await transaction.get(crew)).data();
      if (data == null) return;
      if (data['openReportCount'] == null || data['memberCount'] == null) {
        throw const ServerException(
          message: 'Actualiza los datos anteriores del equipo antes de eliminarlo.',
        );
      }
      if (data['openReportCount'] != 0 || data['assignedCrewId'] != null) {
        throw const ServerException(
          message:
              'El registro está en uso. Finaliza el reporte o libera el camión.',
        );
      }
      final roster = (data['memberIds'] as List?)?.cast<String>();
      if (roster == null && data['memberCount'] != 0) {
        throw const ServerException(
          message:
              'El registro de integrantes cambió. Actualiza el equipo y vuelve a intentar.',
        );
      }
      final truck = await _vehicleToRelease(transaction, crew, data);
      final members = <String>[];
      for (final uid in roster ?? const <String>[]) {
        final profile = (await transaction.get(_users.doc(uid))).data();
        if (profile?['teamId'] == crewId) members.add(uid);
      }
      for (final uid in members) {
        transaction.update(_users.doc(uid), {
          'teamId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      _releaseVehicle(transaction, truck, data);
      transaction.delete(crew);
    });
  }

  Future<void> _recordLegacyRoster(
    DocumentReference<Map<String, dynamic>> crew,
  ) async {
    final members = await _legacyMembers(crew.id);
    await _firestore.runTransaction((transaction) async {
      final data = (await transaction.get(crew)).data();
      if (data == null || data['memberIds'] != null || data['memberCount'] == 0) {
        return;
      }
      if (data['memberCount'] != members.length ||
          members.isEmpty ||
          members.length > MunicipalCrewEntity.maxMembers) {
        throw const ServerException(
          message: 'No se pudo verificar la lista de integrantes del equipo.',
        );
      }
      if (data['openReportCount'] != 0) {
        throw const ServerException(
          message:
              'El equipo tiene un reporte activo. Finalízalo antes de eliminarlo.',
        );
      }
      // Keep the leader first if the legacy record identifies one by name.
      String? leader;
      for (final uid in members) {
        final profile = (await transaction.get(_users.doc(uid))).data();
        if (profile?['teamId'] != crew.id) {
          throw const ServerException(
            message:
                'Los integrantes cambiaron. Actualiza el equipo y vuelve a intentar.',
          );
        }
        if (profile?['name'] == data['leadStaffName']) leader ??= uid;
      }
      transaction.update(crew, {
        'memberIds': [
          if (leader != null) leader,
          ...members.where((uid) => uid != leader),
        ],
        'crewMembersCount': members.length,
      });
    });
  }

  @override
  Future<List<ReportDto>> getCrewActiveReports(String crewId) async {
    final snapshot = await _reports
        .where('assignedToTeamId', isEqualTo: crewId)
        .where('status', whereIn: _openStatuses)
        .get(_server)
        .timeout(_readTimeout);
    return snapshot.docs.map((doc) => ReportDto.fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<Set<String>> getBusyStaffIds() async {
    final open = await _reports
        .where('status', whereIn: _openStatuses)
        .get(_server)
        .timeout(_readTimeout);
    return {
      for (final report in open.docs) ..._individualAssignees(report.data()),
    };
  }

  List<String> _individualAssignees(Map<String, dynamic> report) {
    if ((report['assignedToTeamId'] as String?)?.isNotEmpty == true) return [];
    return (report['assignedStaffIds'] as List?)?.cast<String>() ??
        [
          if (report['assignedStaffId'] is String)
            report['assignedStaffId'] as String,
        ];
  }

  Future<void> _requireFreeStaff(
    Transaction transaction,
    String uid, {
    String? reportId,
  }) async {
    final lock = (await transaction.get(
      _users.doc(uid).collection('operations').doc('dispatch'),
    )).data();
    final reserved = lock?['reportId'] as String?;
    if (reserved != null && reserved != reportId) {
      final report = (await transaction.get(_reports.doc(reserved))).data();
      if (report != null &&
          _openStatuses.contains(report['status']) &&
          _individualAssignees(report).contains(uid)) {
        throw const ServerException(
          message:
              'Una de las personas seleccionadas ya está asignada a otro reporte.',
        );
      }
    }
    final active = (await transaction.get(
      _users.doc(uid).collection('operations').doc('activeTask'),
    )).data();
    if ((active?['reportIds'] as List?)?.isNotEmpty == true) {
      throw const ServerException(
        message: 'Una de las personas seleccionadas tiene una tarea en curso.',
      );
    }
  }

  void _requireAssignableReport(Map<String, dynamic> current) {
    if (!const [
      'pending',
      'pendiente',
      'assigned',
      'asignado',
    ].contains(current['status'])) {
      throw const ServerException(
        message: 'El reporte ya no admite asignaciones.',
      );
    }
  }

  @override
  Future<ReportDto> assignReportToStaff({
    required String reportId,
    required List<String> staffIds,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  }) async {
    if (staffIds.isEmpty ||
        staffIds.toSet().length != staffIds.length ||
        staffIds.any((id) => id.isEmpty)) {
      throw const ServerException(
        message: 'Selecciona al menos una persona sin duplicados.',
      );
    }
    final fields = await writeReportStatus(
      report: _reports.doc(reportId),
      changes: {
        'status': 'assigned',
        'assignedToTeamId': null,
        'assignedToTeamName': null,
        'assignedStaffId': null,
        'assignedStaffIds': staffIds,
        'assignedVehicle': null,
        if (priority != null) 'priority': priority.toDbString(),
      },
      audit: ReportAudit(
        userId: adminId,
        userName: adminName,
        role: 'admin',
        comment: instructions?.isNotEmpty == true
            ? instructions!
            : 'Personal de limpieza asignado al reporte.',
      ),
      prepare: (transaction, current) async {
        _requireAssignableReport(current);
        final previous = _individualAssignees(current);
        if (previous.length == staffIds.length &&
            previous.every(staffIds.contains)) {
          throw const ServerException(
            message: 'Este personal ya está asignado al reporte.',
          );
        }
        final names = <String>[];
        for (final uid in staffIds) {
          final data = (await transaction.get(_users.doc(uid))).data();
          if (data == null ||
              data['isActive'] == false ||
              !const ['staff', 'personal'].contains(data['role']) ||
              (data['teamId'] as String?)?.isNotEmpty == true) {
            throw const ServerException(
              message:
                  'Una de las personas seleccionadas ya no está disponible.',
            );
          }
          await _requireFreeStaff(transaction, uid, reportId: reportId);
          names.add(UserDto.fromMap(data, uid).name);
        }
        for (final uid in staffIds) {
          transaction.set(
            _users.doc(uid).collection('operations').doc('dispatch'),
            {'reportId': reportId, 'updatedAt': FieldValue.serverTimestamp()},
          );
        }
        return {'assignedStaffName': names.join(', ')};
      },
    );
    return ReportDto.fromMap(fields, reportId);
  }

  @override
  Future<ReportDto> assignReportToCrew({
    required String reportId,
    required MunicipalCrewEntity crew,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  }) async {
    final legacy = crew.memberIds == null
        ? await _legacyMembers(crew.id)
        : const <String>[];
    final fields = await writeReportStatus(
      report: _reports.doc(reportId),
      changes: {
        'status': 'assigned',
        'assignedToTeamId': crew.id,
        'assignedStaffId': null,
        'assignedStaffIds': <String>[],
        if (priority != null) 'priority': priority.toDbString(),
      },
      audit: ReportAudit(
        userId: adminId,
        userName: adminName,
        role: 'admin',
        comment: instructions?.isNotEmpty == true
            ? instructions!
            : 'Asignado al equipo ${crew.name}.',
      ),
      prepare: (transaction, current) async {
        _requireAssignableReport(current);
        final data = (await transaction.get(_crews.doc(crew.id))).data();
        if (data == null ||
            !MunicipalCrewDto.fromMap(data, crew.id).toDomain().canDispatch ||
            current['assignedToTeamId'] == crew.id) {
          throw const ServerException(
            message: 'El equipo seleccionado ya no está disponible.',
          );
        }
        final members = (data['memberIds'] as List?)?.cast<String>() ?? legacy;
        if (members.isEmpty || data['memberCount'] != members.length) {
          throw const ServerException(
            message:
                'El equipo necesita integrantes disponibles. Actualiza la lista.',
          );
        }
        for (final uid in members) {
          final user = (await transaction.get(_users.doc(uid))).data();
          if (user == null ||
              user['isActive'] == false ||
              user['teamId'] != crew.id ||
              !const ['staff', 'personal'].contains(user['role'])) {
            throw const ServerException(
              message: 'Un integrante del equipo ya no está disponible.',
            );
          }
          await _requireFreeStaff(transaction, uid, reportId: reportId);
        }
        final vehicleId = data['vehicleId'] as String?;
        final truck = vehicleId == null
            ? data
            : (await transaction.get(_vehicles.doc(vehicleId))).data();
        if (truck == null ||
            (vehicleId != null && !_vehicleAvailable(truck, crew.id))) {
          throw const ServerException(
            message: 'El camión del equipo ya no está disponible.',
          );
        }
        return {
          'assignedToTeamName': data['name'],
          'assignedStaffName': data['leadStaffName'],
          'assignedVehicle':
              '${truck['vehicleCode']} • ${truck['vehiclePlate']}',
        };
      },
    );
    return ReportDto.fromMap(fields, reportId);
  }

  @override
  Future<ReportDto> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  }) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada.');
    }

    try {
      final updated = await writeReportStatus(
        report: _firestore.collection('reports').doc(reportId),
        changes: {'priority': priority.toDbString()},
      );
      return ReportDto.fromMap(updated, reportId);
    } catch (e) {
      throw ServerException(message: 'Error al actualizar prioridad: $e');
    }
  }

  @override
  Future<List<UserEntity>> getStaffMembers() async {
    if (!_isFirebaseReady && _customFirestore == null) return [];

    try {
      // Solo consulta usuarios cuyo rol sea 'staff'. Privacidad garantizada.
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['staff', 'personal'])
          .get(_server);

      final list = querySnapshot.docs
          .map((doc) => UserDto.fromMap(doc.data(), doc.id).toDomain())
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw ServerException(
        message: 'Error al obtener personal de limpieza: $e',
      );
    }
  }

  @override
  Future<UserEntity?> searchUserByExactEmail(String email) async {
    if (!_isFirebaseReady && _customFirestore == null) return null;

    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    try {
      // Búsqueda estricta por igualdad exacta: NO expone ni lista a otros ciudadanos
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalized)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return UserDto.fromMap(doc.data(), doc.id).toDomain();
    } catch (e) {
      throw ServerException(message: 'Error al buscar usuario por correo: $e');
    }
  }

  @override
  Future<void> updateUserRole({
    required String userId,
    required UserRole newRole,
  }) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada.');
    }

    try {
      final updateData = <String, dynamic>{
        'role': newRole.toDbString(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final user = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final current = (await transaction.get(user)).data();
        if (current == null) {
          throw const ServerException(message: 'El usuario no existe.');
        }
        if (newRole == UserRole.citizen) {
          if ((current['teamId'] as String?)?.isNotEmpty == true) {
            throw const ServerException(
              message:
                  'Retira a esta persona desde Gestión de Equipos antes de cambiar su rol.',
            );
          }
          await _requireFreeStaff(transaction, userId);
          if (current['teamId'] == '') {
            updateData['teamId'] = FieldValue.delete();
          }
        }
        transaction.update(user, updateData);
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Error al actualizar rol del usuario: $e');
    }
  }
}
