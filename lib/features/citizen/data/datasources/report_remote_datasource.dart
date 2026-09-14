import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/report_category_entity.dart';
import '../models/report_category_dto.dart';
import '../models/report_dto.dart';

/// Contrato abstracto para la fuente de datos remota de reportes de residuos.
///
/// Ubicación: `lib/features/citizen/data/datasources/report_remote_datasource.dart`
/// Capa: Data (DataSources)
abstract class ReportRemoteDataSource {
  Future<List<ReportCategoryDto>> getCategories();

  Future<String?> uploadReportImage({
    required List<int> imageBytes,
    required String fileName,
  });

  Future<ReportDto> createReport(ReportDto report);

  Future<List<ReportDto>> getMyReports(String citizenId);

  Future<ReportDto> getReportById(String reportId);
}

/// Implementación concreta de ReportRemoteDataSource con Cloud Firestore y Firebase Storage.
class FirebaseReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final FirebaseFirestore? _customFirestore;
  final FirebaseStorage? _customStorage;

  FirebaseReportRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _customFirestore = firestore,
        _customStorage = storage;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  @override
  Future<List<ReportCategoryDto>> getCategories() async {
    if (!_isFirebaseReady && _customFirestore == null) {
      // Retornar catálogo por defecto si Firebase aún no está conectado
      return ReportCategoryEntity.defaultCategories
          .map(ReportCategoryDto.fromEntity)
          .toList();
    }

    try {
      final snapshot = await _firestore
          .collection('report_categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      if (snapshot.docs.isEmpty) {
        // Semillero automático: guardar las categorías estándar en Firestore
        final defaultDtos = ReportCategoryEntity.defaultCategories
            .map(ReportCategoryDto.fromEntity)
            .toList();

        for (final cat in defaultDtos) {
          try {
            await _firestore
                .collection('report_categories')
                .doc(cat.id)
                .set(cat.toMap());
          } catch (_) {}
        }
        return defaultDtos;
      }

      return snapshot.docs
          .map((doc) => ReportCategoryDto.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (_) {
      // Si ocurre un error de permisos u offline, proveer el catálogo por defecto
      return ReportCategoryEntity.defaultCategories
          .map(ReportCategoryDto.fromEntity)
          .toList();
    }
  }

  @override
  Future<String?> uploadReportImage({
    required List<int> imageBytes,
    required String fileName,
  }) async {
    if (!_isFirebaseReady && _customStorage == null) {
      return null;
    }

    try {
      final ref = _storage.ref().child('reports/$fileName');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
      );

      final uploadTask = await ref.putData(
        Uint8List.fromList(imageBytes),
        metadata,
      );

      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'No se pudo subir la fotografía de evidencia: ${e.message ?? e.code}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(message: 'Error al procesar la imagen: $e');
    }
  }

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
}
