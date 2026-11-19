import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_report_community_repository.dart';
import '../../domain/entities/report_community.dart';
import '../../domain/repositories/report_community_repository.dart';

final reportCommunityRepositoryProvider = Provider<ReportCommunityRepository>(
  (ref) => FirebaseReportCommunityRepository(),
);

final reportCommunitySummaryProvider = StreamProvider.autoDispose
    .family<ReportCommunitySummary, String>(
      (ref, id) =>
          ref.watch(reportCommunityRepositoryProvider).watchSummary(id),
    );

final reportParticipationProvider = StreamProvider.autoDispose
    .family<ReportParticipation, (String, String)>(
      (ref, args) => ref
          .watch(reportCommunityRepositoryProvider)
          .watchParticipation(args.$1, args.$2),
    );
