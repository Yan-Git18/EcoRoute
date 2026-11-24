import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/community_report_document.dart';
import '../../../../core/services/firestore_media.dart';
import '../../../../core/services/report_status_transaction.dart';
import '../../domain/repositories/report_repository.dart';
import '../models/report_dto.dart';

/// Contrato abstracto para la fuente de datos remota de reportes de residuos en Firestore.
///
/// Principio SRP: Responsabilidad única de guardar y consultar documentos de reportes e historial.
abstract class ReportRemoteDataSource {
  Future<ReportDto> createReport(ReportDto report, {List<Uint8List> photos = const []});
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
  Future<ReportDto> createReport(ReportDto report, {List<Uint8List> photos = const []}) async {
    if (!_isFirebaseReady && _customFirestore == null) {
      throw const ServerException(
        message: 'Servicio de base de datos no disponible.',
        code: 'firebase-unavailable',
      );
    }

    try {
      final docRef = _firestore.collection('reports').doc(report.id);
      final batch = _firestore.batch();
      final media = docRef.collection('media');
      final paths = <String>[];
      for (var i = 0; i < photos.length; i++) {
        final photo = media.doc('photo_$i');
        paths.add(photo.path);
        batch.set(photo, FirestoreMedia.document(photos[i]));
      }
      final eventId = const Uuid().v4();
      final fields = {
        ...report.toMap(),
        'imagePaths': paths,
        'createdAt': FieldValue.serverTimestamp(),
        'statusEventId': eventId,
      };
      final audit = ReportAudit(
        userId: report.citizenId,
        userName: report.citizenName,
        role: 'citizen',
        comment: 'Reporte registrado por el ciudadano.',
      );
      batch.set(docRef, fields);
      batch.set(communityReportRef(docRef), communityReportDocument(fields));
      batch.set(docRef.collection('history').doc(eventId), audit.event('none', 'pending'));
      await batch.commit();

      return ReportDto.fromMap(
        {...fields, 'createdAt': Timestamp.fromDate(report.createdAt), 'updatedAt': null},
        report.id,
        history: [
          ReportHistoryItemDto.fromMap({
            ...audit.event('none', 'pending'),
            'timestamp': Timestamp.fromDate(report.createdAt),
          }),
        ],
      );
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Error de Firestore al enviar reporte [${e.code}]: ${e.message}');
      }
      throw ServerException(
        message: e.message ?? e.code,
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error inesperado al enviar reporte: $e');
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
      DocumentSnapshot<Map<String, dynamic>>? privateReport;
      try {
        privateReport = await docRef.get(const GetOptions(source: Source.server));
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied' && error.code != 'unavailable') rethrow;
      }
      final privateData = privateReport?.data();
      if (privateData != null) {
        final history = await docRef.collection('history')
            .orderBy('timestamp').get(const GetOptions(source: Source.server));
        return ReportDto.fromMap(
          privateData,
          reportId,
          history: history.docs.map((doc) => ReportHistoryItemDto.fromMap(doc.data())).toList(),
        );
      }

      final publicData = (await communityReportRef(docRef).get()).data();
      if (publicData == null) {
        throw const ServerException(message: 'El reporte solicitado no existe.');
      }
      return ReportDto.fromMap(publicData, reportId);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Error al consultar el reporte: $e');
    }
  }

  @override
  Future<List<ReportDto>> getAllReports() async {
    if (!_isFirebaseReady && _customFirestore == null) return [];

    try {
      final cutoff = DateTime.now().toUtc().subtract(
        const Duration(days: ReportRepository.communityReportWindowDays),
      );
      final snapshot = await _firestore
          .collection(communityReportsCollection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .orderBy('createdAt', descending: true)
          .limit(ReportRepository.communityReportLimit)
          .get();
      return snapshot.docs
          .map((doc) => ReportDto.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Error al consultar reportes comunitarios: $e');
    }
  }

  @override
  Future<void> cancelReport({required String reportId, String? reason}) async {
    final user = _isFirebaseReady ? FirebaseAuth.instance.currentUser : null;
    if (user == null) throw const ServerException(message: 'Inicia sesión para cancelar el reporte.');

    try {
      final docRef = _firestore.collection('reports').doc(reportId);
      final comment = reason ?? 'Reporte cancelado por el ciudadano.';
      await writeReportStatus(
        report: docRef,
        changes: {'status': 'cancelled', 'cancellationReason': comment},
        audit: ReportAudit(
          userId: user.uid,
          userName: user.displayName ?? 'Ciudadano',
          role: 'citizen',
          comment: comment,
        ),
      );
    } catch (e) {
      throw ServerException(message: 'Error al cancelar el reporte: $e');
    }
  }
}
