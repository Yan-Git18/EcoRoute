import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/report_community_providers.dart';

class ReportCommunitySummaryLabel extends ConsumerWidget {
  final String reportId;
  final bool showWhenEmpty;

  const ReportCommunitySummaryLabel({
    super.key,
    required this.reportId,
    this.showWhenEmpty = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(reportCommunitySummaryProvider(reportId)).value;
    if (summary == null) return const SizedBox.shrink();
    final supports = summary.supportCount;
    final count = summary.ratingCount;
    if (!showWhenEmpty && supports == 0 && count == 0) {
      return const SizedBox.shrink();
    }

    final average = summary.averageRating
        ?.toStringAsFixed(1)
        .replaceFirst('.', ',');
    final parts = [
      supports == 1 ? '1 apoyo' : '$supports apoyos',
      if (average != null)
        '$average/5 · $count ${count == 1 ? 'calificación' : 'calificaciones'}',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        parts.join(' · '),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
