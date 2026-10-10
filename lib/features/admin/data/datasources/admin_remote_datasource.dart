import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../citizen/data/models/report_dto.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/municipal_crew_entity.dart';

/// Contrato para la fuente remota de datos del administrador municipal.
abstract class AdminRemoteDataSource {
  Future<List<ReportDto>> getAllReports();
  Future<List<MunicipalCrewEntity>> getAvailableCrews();
  Future<ReportDto> assignReportToCrew({
    required String reportId,
    required MunicipalCrewEntity crew,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  });
  Future<void> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  });
}

/// Implementación concreta con Cloud Firestore.
class FirebaseAdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final FirebaseFirestore? _customFirestore;

  FirebaseAdminRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  static const List<MunicipalCrewEntity> _defaultMunicipalCrews = [
    MunicipalCrewEntity(
      id: 'crew-north',
      name: 'Cuadrilla Zona Norte',
      zone: 'Sector 1 y 2 (Los Próceres / Las Palmas)',
      leadStaffName: 'Mario Limpieza',
      vehicleCode: 'Camión #04',
      vehiclePlate: 'ECR-882',
      vehicleType: 'Camión Compactador 15m³',
      crewMembersCount: 3,
      activeTasksCount: 2,
      isAvailable: true,
      status: MunicipalCrewStatus.onRoute,
      latitude: -12.0410,
      longitude: -77.0390,
    ),
    MunicipalCrewEntity(
      id: 'crew-south',
      name: 'Cuadrilla Zona Sur',
      zone: 'Sector 3 y 4 (Av. Huaylas / Chorrillos)',
      leadStaffName: 'Carlos Cuadrilla',
      vehicleCode: 'Camión #02',
      vehiclePlate: 'ECR-341',
      vehicleType: 'Furgón Barrendero Ligero',
      crewMembersCount: 2,
      activeTasksCount: 1,
      isAvailable: true,
      status: MunicipalCrewStatus.onRoute,
      latitude: -12.0530,
      longitude: -77.0470,
    ),
    MunicipalCrewEntity(
      id: 'crew-center',
      name: 'Cuadrilla Centro Histórico',
      zone: 'Sector Central (Jr. Amazonas / Plaza)',
      leadStaffName: 'Rosa Recolectora',
      vehicleCode: 'Camión #01',
      vehiclePlate: 'ECR-119',
      vehicleType: 'Camión Recolector Urbano',
      crewMembersCount: 4,
      activeTasksCount: 3,
      isAvailable: true,
      status: MunicipalCrewStatus.onRoute,
      latitude: -12.0465,
      longitude: -77.0430,
    ),
    MunicipalCrewEntity(
      id: 'crew-spec',
      name: 'Cuadrilla Especial Desbordes',
      zone: 'Todos los sectores (Respuesta Rápida)',
      leadStaffName: 'Jorge Parque',
      vehicleCode: 'Camión #05',
      vehiclePlate: 'ECR-554',
      vehicleType: 'Camión Volquete Pesado',
      crewMembersCount: 3,
      activeTasksCount: 0,
      isAvailable: true,
      status: MunicipalCrewStatus.available,
      latitude: -12.0480,
      longitude: -77.0360,
    ),
  ];

  @override
  Future<List<ReportDto>> getAllReports() async {
    if (!_isFirebaseReady && _customFirestore == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportDto.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Error al consultar reportes en Firestore: $e');
    }
  }

  @override
  Future<List<MunicipalCrewEntity>> getAvailableCrews() async {
    // Si en el futuro existe la colección 'crews' en Firestore, se puede consultar aquí.
    return _defaultMunicipalCrews;
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
        'assignedStaffName': crew.leadStaffName,
        'assignedVehicle': '${crew.vehicleCode} • ${crew.vehiclePlate}',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (priority != null) {
        updateMap['priority'] = priority.toDbString();
      }

      await docRef.update(updateMap);

      // Registrar auditoría en historial
      try {
        await docRef.collection('history').add({
          'previousStatus': 'pending',
          'newStatus': 'assigned',
          'changedByUserId': adminId,
          'changedByUserName': adminName,
          'changedByUserRole': 'admin',
          'comment': instructions?.isNotEmpty == true
              ? instructions!
              : 'Asignado a ${crew.name} (${crew.vehicleCode}) por el Administrador Municipal.',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      final snapshot = await docRef.get();
      return ReportDto.fromMap(snapshot.data()!, snapshot.id);
    } catch (e) {
      throw ServerException(message: 'Error al asignar cuadrilla al reporte: $e');
    }
  }

  @override
  Future<void> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  }) async {
    if (!_isFirebaseReady && _customFirestore == null) return;

    try {
      await _firestore.collection('reports').doc(reportId).update({
        'priority': priority.toDbString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(message: 'Error al actualizar prioridad: $e');
    }
  }
}
