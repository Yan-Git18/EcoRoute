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
      try {
        await docRef.collection('history').add({
          'previousStatus': 'none',
          'newStatus': report.status,
          'changedByUserId': report.citizenId,
          'changedByUserName': report.citizenName,
          'changedByUserRole': 'citizen',
          'comment': 'Reporte registrado por el ciudadano.',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      return report;
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
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (!doc.exists || doc.data() == null) {
        throw const ServerException(message: 'El reporte solicitado no existe.');
      }

      return ReportDto.fromMap(doc.data()!, doc.id);
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
