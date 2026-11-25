import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../citizen/domain/entities/report_entity.dart';

class AdminReportCard extends StatelessWidget {
  const AdminReportCard({
    super.key,
    required this.report,
    required this.onViewDetail,
  });

  final ReportEntity report;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onViewDetail,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          report.reportNumber,
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          DateFormatter.formatTimeAgo(report.createdAt),
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        _ReportStatusLabel(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportStatusLabel extends StatelessWidget {
  const _ReportStatusLabel({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      ReportStatus.pending => (
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
      ),
      ReportStatus.assigned => (
        status.backgroundColor,
        const Color(0xFF5B21B6),
      ),
      ReportStatus.inProgress => (
        status.backgroundColor,
        const Color(0xFF1E40AF),
      ),
      ReportStatus.resolved => (status.backgroundColor, AppColors.primaryDark),
      ReportStatus.cancelled => (AppColors.divider, AppColors.textSecondary),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          status == ReportStatus.pending ? status.label : status.displayLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
