import '../../../../core/utils/result.dart';
import '../entities/report_community.dart';

abstract interface class ReportCommunityRepository {
  Stream<ReportCommunitySummary> watchSummary(String reportId);
  Stream<ReportParticipation> watchParticipation(
    String reportId,
    String userId,
  );
  Future<Result<void>> support(String reportId);
  Future<Result<void>> rate(String reportId, int rating);
}
