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
  Future<MunicipalCrewDto> createCrew(MunicipalCrewEntity crew);
  Future<void> updateCrew(MunicipalCrewEntity crew);
  Future<void> deleteCrew(String crewId);
  Future<ReportDto> assignReportToCrew({
    required String reportId,
    required MunicipalCrewEntity crew,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  });
  Future<ReportDto> updateReportPriority({required String reportId, required ReportPriority priority});

  /// Obtiene únicamente los usuarios con rol de personal (staff).
  /// Protege la privacidad evitando consultar cuentas ciudadanas.
  Future<List<UserEntity>> getStaffMembers();

  /// Búsqueda estricta por correo exacto para no filtrar correos de ciudadanos.
  Future<UserEntity?> searchUserByExactEmail(String email);

  /// Asigna o revierte el rol de un usuario en Cloud Firestore.
  Future<void> updateUserRole({
    required String userId,
    required UserRole newRole,
    String? teamId,
  });
}

class _FirestoreReportCursor implements AdminReportCursor {
  const _FirestoreReportCursor(this.document);

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
}

/// Implementación concreta con Cloud Firestore.
class FirebaseAdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final FirebaseFirestore? _customFirestore;

  FirebaseAdminRemoteDataSourceImpl({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  static const _readTimeout = Duration(seconds: 12);

  @override
  Future<AdminReportPage<ReportDto>> getReportsPage({AdminReportCursor? after}) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada.');
    }

    try {
      var query = _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true);
      if (after != null) {
        query = query.startAfterDocument((after as _FirestoreReportCursor).document);
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
      throw ServerException(message: 'No se pudieron consultar los reportes.', code: e.code);
    } catch (e) {
      throw ServerException(message: 'Error al consultar reportes en Firestore: $e');
    }
  }

  @override
  Future<AdminReportTotals> getReportTotals() async {
    final reports = _firestore.collection('reports');
    Future<int> countReports(Query<Map<String, dynamic>> query) async =>
        (await query.count().get().timeout(_readTimeout)).count!;

    Future<int> countStatus(ReportStatus status) => countReports(
      reports.where('status', whereIn: [
        status.toDbString(),
        status.toDbString().toUpperCase(),
        status.label.toLowerCase(),
        status.label,
        status.label.toUpperCase(),
      ]),
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
      pending: (total - assigned - inProgress - resolved - cancelled).clamp(0, total),
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
      final snapshot = await _firestore
          .collection('crews')
          .get(const GetOptions(source: Source.server))
          .timeout(_readTimeout);
      return snapshot.docs.map((doc) => MunicipalCrewDto.fromMap(doc.data(), doc.id)).toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: 'No se pudieron consultar las cuadrillas.', code: e.code);
    } catch (e) {
      throw ServerException(message: 'Error al consultar cuadrillas en Firestore: $e');
    }
  }

  @override
  Future<MunicipalCrewDto> createCrew(MunicipalCrewEntity crew) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      return MunicipalCrewDto.fromDomain(crew);
    }

    try {
      final docRef = crew.id.isNotEmpty
          ? _firestore.collection('crews').doc(crew.id)
          : _firestore.collection('crews').doc();
      final crewWithId = crew.copyWith(id: docRef.id);
      final dto = MunicipalCrewDto.fromDomain(crewWithId);
      await docRef.set({...dto.toMap(), 'openReportCount': 0, 'memberCount': 0});
      return dto;
    } catch (e) {
      throw ServerException(message: 'Error al registrar cuadrilla en Firestore: $e');
    }
  }

  @override
  Future<void> updateCrew(MunicipalCrewEntity crew) async {
    if (!_isFirebaseReady && _customFirestore == null) return;

    try {
      final dto = MunicipalCrewDto.fromDomain(crew);
      await _firestore.collection('crews').doc(crew.id).set(
        dto.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw ServerException(message: 'Error al actualizar cuadrilla en Firestore: $e');
    }
  }

  @override
  Future<void> deleteCrew(String crewId) async {
    if (!_isFirebaseReady && _customFirestore == null) return;

    try {
      final crew = _firestore.collection('crews').doc(crewId);
      await _firestore.runTransaction((transaction) async {
        final data = (await transaction.get(crew)).data();
        if (data == null) return;
        if (data['openReportCount'] != 0 || data['memberCount'] != 0) {
          throw const ServerException(
            message: 'Reasigna los reportes abiertos y el personal antes de dar de baja la cuadrilla.',
            code: 'crew-in-use',
          );
        }
        transaction.delete(crew);
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Error al eliminar cuadrilla en Firestore: $e');
    }
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
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada.');
    }

    try {
      final docRef = _firestore.collection('reports').doc(reportId);

      final updateMap = <String, dynamic>{
        'status': ReportStatus.assigned.toDbString(),
        'assignedToTeamId': crew.id,
        'assignedToTeamName': crew.name,
        'assignedStaffId': null,
        'assignedStaffName': crew.leadStaffName,
        'assignedVehicle': '${crew.vehicleCode} • ${crew.vehiclePlate}',
      };

      if (priority != null) {
        updateMap['priority'] = priority.toDbString();
      }

      final updated = await writeReportStatus(
        report: docRef,
        changes: updateMap,
        audit: ReportAudit(
          userId: adminId,
          userName: adminName,
          role: 'admin',
          comment: instructions?.isNotEmpty == true
              ? instructions!
              : 'Asignado a ${crew.name} (${crew.vehicleCode}) por el Administrador Municipal.',
        ),
      );
      return ReportDto.fromMap(updated, reportId);
    } catch (e) {
      throw ServerException(message: 'Error al asignar cuadrilla al reporte: $e');
    }
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
          .where('role', isEqualTo: 'staff')
          .get();

      final list = querySnapshot.docs
          .map((doc) => UserDto.fromMap(doc.data(), doc.id).toDomain())
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw ServerException(message: 'Error al obtener personal de limpieza: $e');
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
    String? teamId,
  }) async {
    if (!_isFirebaseReady && _customFirestore == null) return;

    try {
      final updateData = <String, dynamic>{
        'role': newRole.toDbString(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final user = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final current = (await transaction.get(user)).data();
        if (current == null) throw const ServerException(message: 'El usuario no existe.');
        final storedTeam = current['teamId'];
        final previousTeam = storedTeam is String && storedTeam.isNotEmpty ? storedTeam : null;
        final nextTeam = newRole == UserRole.citizen
            ? null
            : (teamId?.isNotEmpty == true ? teamId : previousTeam);
        if (nextTeam != storedTeam) {
          updateData['teamId'] = nextTeam ?? FieldValue.delete();
        }
        if (nextTeam != previousTeam) {
          for (final (crewId, delta) in [(previousTeam, -1), (nextTeam, 1)]) {
            if (crewId == null || crewId.isEmpty) continue;
            transaction.update(_firestore.collection('crews').doc(crewId), {
              'memberCount': FieldValue.increment(delta),
              'memberActivity': {'userId': userId, 'updatedAt': FieldValue.serverTimestamp()},
            });
          }
        }
        transaction.update(user, updateData);
      });
    } catch (e) {
      throw ServerException(message: 'Error al actualizar rol del usuario: $e');
    }
  }
}
