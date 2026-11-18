import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/report_dto.dart';

/// Contrato abstracto para la fuente de datos remota de reportes de residuos en Firestore.
///
/// Principio SRP: Responsabilidad única de guardar y consultar documentos de reportes e historial.
abstract class ReportRemoteDataSource {
  Future<ReportDto> createReport(ReportDto report);
  Future<List<ReportDto>> getMyReports(String citizenId);
  Future<ReportDto> getReportById(String reportId);
  Future<List<ReportDto>> getAllReports();
  Future<void> cancelReport({required String reportId, String? reason});
}

/// Implementación concreta de ReportRemoteDataSource con Cloud Firestore.
class FirebaseReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final FirebaseFirestore? _customFirestore;

  FirebaseReportRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<ReportDto> createReport(ReportDto report) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(
        message: 'Servicio de base de datos no disponible.',
        code: 'firebase-unavailable',
      );
    }

    try {
      final docRef = _firestore.collection('reports').doc(report.id);
      await docRef.set(report.toMap());

      // Registrar auditoría inicial en la subcolección 'history'
      final initialHistoryItem = ReportHistoryItemDto(
        previousStatus: 'none',
        newStatus: report.status,
        changedByUserId: report.citizenId,
        changedByUserName: report.citizenName,
        changedByUserRole: 'citizen',
        comment: 'Reporte registrado por el ciudadano.',
        timestamp: report.createdAt,
      );

      try {
        await docRef.collection('history').add({
          'previousStatus': initialHistoryItem.previousStatus,
          'newStatus': initialHistoryItem.newStatus,
          'changedByUserId': initialHistoryItem.changedByUserId,
          'changedByUserName': initialHistoryItem.changedByUserName,
          'changedByUserRole': initialHistoryItem.changedByUserRole,
          'comment': initialHistoryItem.comment,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      return ReportDto(
        id: report.id,
        reportNumber: report.reportNumber,
        citizenId: report.citizenId,
        citizenName: report.citizenName,
        citizenPhone: report.citizenPhone,
        categoryId: report.categoryId,
        categoryName: report.categoryName,
        categoryIcon: report.categoryIcon,
        description: report.description,
        priority: report.priority,
        status: report.status,
        latitude: report.latitude,
        longitude: report.longitude,
        address: report.address,
        reference: report.reference,
        imageUrls: report.imageUrls,
        createdAt: report.createdAt,
        updatedAt: report.updatedAt,
        assignedToTeamId: report.assignedToTeamId,
        assignedToTeamName: report.assignedToTeamName,
        assignedStaffName: report.assignedStaffName,
        assignedVehicle: report.assignedVehicle,
        evidenceImageUrl: report.evidenceImageUrl,
        resolutionNotes: report.resolutionNotes,
        history: [initialHistoryItem],
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const ServerException(
          message: 'Permisos insuficientes en Cloud Firestore. Verifique las Reglas de Seguridad para la colección "reports".',
          code: 'permission-denied',
        );
      }
      throw ServerException(
        message: 'Error al registrar el reporte en la base de datos: ${e.message ?? e.code}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Error inesperado al guardar el reporte: $e');
    }
  }

  @override
  Future<List<ReportDto>> getMyReports(String citizenId) async {
    if (!_isFirebaseReady && _customFirestore == null) return [];

    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('citizenId', isEqualTo: citizenId)
          .get();

      final list = snapshot.docs
          .map((doc) => ReportDto.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw ServerException(message: 'Error al consultar sus reportes: $e');
    }
  }

  @override
  Future<ReportDto> getReportById(String reportId) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(message: 'Base de datos no inicializada');
    }

    try {
      final docRef = _firestore.collection('reports').doc(reportId);
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) {
        throw const ServerException(message: 'El reporte solicitado no existe.');
      }

      List<ReportHistoryItemDto> historyList = [];
      try {
        final historySnapshot = await docRef.collection('history').get();
        historyList = historySnapshot.docs
            .map((hDoc) => ReportHistoryItemDto.fromMap(hDoc.data()))
            .toList();
        historyList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      } catch (_) {}

      return ReportDto.fromMap(
        doc.data()!,
        doc.id,
        history: historyList,
      );
    } catch (e) {
      throw ServerException(message: 'Error al consultar el reporte: $e');
    }
  }

  @override
  Future<List<ReportDto>> getAllReports() async {
    if (!_isFirebaseReady && _customFirestore == null) return [];

    try {
      final snapshot = await _firestore.collection('reports').get();
      final list = snapshot.docs
          .map((doc) => ReportDto.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw ServerException(message: 'Error al consultar reportes comunitarios: $e');
    }
  }

  @override
  Future<void> cancelReport({required String reportId, String? reason}) async {
    if (!_isFirebaseReady && _customFirestore == null) return;

    try {
      final docRef = _firestore.collection('reports').doc(reportId);
      await docRef.update({
        'status': 'cancelled',
        'cancellationReason': reason ?? 'Cancelado por el ciudadano',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await docRef.collection('history').add({
          'previousStatus': 'pending',
          'newStatus': 'cancelled',
          'changedByUserRole': 'citizen',
          'comment': reason ?? 'Reporte cancelado por el ciudadano.',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    } catch (e) {
      throw ServerException(message: 'Error al cancelar el reporte: $e');
    }
  }
}
