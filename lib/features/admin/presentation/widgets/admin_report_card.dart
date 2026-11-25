import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../../citizen/presentation/widgets/report_community_summary_label.dart';

class AdminReportCard extends StatelessWidget {
  const AdminReportCard({
    super.key,
    required this.report,
    required this.onAssign,
    required this.onViewDetail,
  });

  final ReportEntity report;
  final VoidCallback? onAssign;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadataStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
    );
    final isPending = report.status == ReportStatus.pending;
    final teamName = report.assignedToTeamName ?? report.assignedStaffName;
    final vehicle = report.assignedVehicle;
    final citizenPhone = report.citizenPhone;

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  report.reportNumber,
                  style: metadataStyle?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  DateFormatter.formatTimeAgo(report.createdAt),
                  style: metadataStyle,
                ),
                _ReportStatusLabel(status: report.status),
                Text(
                  'Prioridad ${report.priority.label.toLowerCase()}',
                  style: metadataStyle?.copyWith(
                    color: report.priority == ReportPriority.high
                        ? const Color(0xFFB91C1C)
                        : AppColors.textSecondary,
                    fontWeight: report.priority == ReportPriority.high
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.categoryName,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              report.address,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Reportado por ${report.citizenName}'
              '${citizenPhone == null || citizenPhone.isEmpty ? '' : ' · $citizenPhone'}',
              style: metadataStyle,
            ),
            if (teamName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  vehicle == null || vehicle.isEmpty
                      ? teamName
                      : '$teamName · $vehicle',
                  style: metadataStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ReportCommunitySummaryLabel(reportId: report.id),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isPending && report.status != ReportStatus.assigned)
                  const Spacer()
                else
                  Flexible(
                    child: isPending
                        ? ElevatedButton(
                            onPressed: onAssign,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Asignar Personal'),
                          )
                        : TextButton(
                            onPressed: onAssign,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryDark,
                            ),
                            child: const Text('Reasignar Personal'),
                          ),
                  ),
                IconButton(
                  tooltip: 'Ver detalle completo',
                  color: AppColors.textSecondary,
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: onViewDetail,
                ),
              ],
            ),
          ],
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
