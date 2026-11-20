import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/entities/report_category_entity.dart';
import '../models/report_category_dto.dart';

/// Contrato abstracto para la fuente de datos de catálogo de categorías.
///
/// Principio SRP: Responsabilidad única de consultar y gestionar categorías.
abstract class CategoryRemoteDataSource {
  Future<List<ReportCategoryDto>> getCategories();
}

/// Implementación concreta de CategoryRemoteDataSource con Cloud Firestore.
class FirebaseCategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final FirebaseFirestore? _customFirestore;

  FirebaseCategoryRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ReportCategoryDto>> getCategories() async {
    if (!_isFirebaseReady && _customFirestore == null) {
      return ReportCategoryEntity.defaultCategories
          .map(ReportCategoryDto.fromEntity)
          .toList();
    }

    try {
      final snapshot = await _firestore
          .collection('report_categories')
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return ReportCategoryEntity.defaultCategories
            .map(ReportCategoryDto.fromEntity)
            .toList();
      }

      return snapshot.docs
          .map((doc) => ReportCategoryDto.fromFirestore(doc.id, doc.data()))
          .toList()
        ..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder == 0 ? a.id.compareTo(b.id) : byOrder;
        });
    } catch (_) {
      return ReportCategoryEntity.defaultCategories
          .map(ReportCategoryDto.fromEntity)
          .toList();
    }
  }
}
