import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/report_community.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_community_repository.dart';

class FirebaseReportCommunityRepository implements ReportCommunityRepository {
  DocumentReference<Map<String, dynamic>> _report(String id) =>
      FirebaseFirestore.instance.collection('reports').doc(id);

  @override
  Stream<ReportCommunitySummary> watchSummary(String reportId) {
    if (Firebase.apps.isEmpty) {
      return Stream.value(const ReportCommunitySummary());
    }
    return _report(
      reportId,
    ).collection('community').doc('summary').snapshots().map((doc) {
      final data = doc.data();
      return ReportCommunitySummary(
        supportCount: data?['supportCount'] as int? ?? 0,
        ratingCount: data?['ratingCount'] as int? ?? 0,
        ratingTotal: data?['ratingTotal'] as int? ?? 0,
      );
    });
  }

  @override
  Stream<ReportParticipation> watchParticipation(
    String reportId,
    String userId,
  ) {
    if (Firebase.apps.isEmpty) return Stream.value(const ReportParticipation());
    return _report(
      reportId,
    ).collection('participants').doc(userId).snapshots().map((doc) {
      final data = doc.data();
      return ReportParticipation(
        supported: data?['supported'] == true,
        rating: data?['rating'] as int?,
      );
    });
  }

  @override
  Future<Result<void>> support(String reportId) =>
      _participate(reportId);

  @override
  Future<Result<void>> rate(String reportId, int rating) =>
      _participate(reportId, rating: rating);

  Future<Result<void>> _participate(String reportId, {int? rating}) async {
    if (rating != null && (rating < 1 || rating > 5)) {
      return const FailureResult(ValidationFailure(message: 'Elige entre 1 y 5 estrellas.'));
    }
    final uid = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const FailureResult(AuthFailure(message: 'Inicia sesión para participar.'));
    }
    final report = _report(reportId);
    final participant = report.collection('participants').doc(uid);
    final summary = report.collection('community').doc('summary');
    try {
      return await FirebaseFirestore.instance.runTransaction<Result<void>>((transaction) async {
        final current = (await transaction.get(report)).data();
        if (current == null) return _invalid('El reporte ya no está disponible.');
        final previous = (await transaction.get(participant)).data();
        final status = ReportStatus.fromString(current['status'] as String? ?? '');
        final supported = previous?['supported'] == true;
        final isAuthor = current['citizenId'] == uid;
        if (rating == null) {
          if (supported) return const Success<void>(null);
          if (isAuthor) return _invalid('Ya eres el autor de este reporte.');
          if (status == ReportStatus.resolved || status == ReportStatus.cancelled) {
            return _invalid('El reporte ya no admite apoyos.');
          }
          transaction.set(participant, {'supported': true}, SetOptions(merge: true));
          transaction.set(summary, {'supportCount': FieldValue.increment(1)}, SetOptions(merge: true));
        } else {
          final previousRating = previous?['rating'];
          if (previousRating == rating) return const Success<void>(null);
          if (previousRating != null) return _invalid('Ya calificaste esta limpieza.');
          if (status != ReportStatus.resolved) return _invalid('El reporte sigue en atención.');
          if (!isAuthor && !supported) return _invalid('Solo pueden calificar el autor y quienes apoyaron.');
          transaction.set(participant, {'rating': rating}, SetOptions(merge: true));
          transaction.set(summary, {
            'ratingCount': FieldValue.increment(1),
            'ratingTotal': FieldValue.increment(rating),
          }, SetOptions(merge: true));
        }
        return const Success<void>(null);
      });
    } catch (_) {
      return const FailureResult(ServerFailure(
        message: 'No se pudo registrar tu participación. Inténtalo de nuevo.',
      ));
    }
  }

  Result<void> _invalid(String message) => FailureResult(ValidationFailure(message: message));
}
