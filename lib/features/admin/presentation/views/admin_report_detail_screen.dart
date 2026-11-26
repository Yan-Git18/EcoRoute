import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../../citizen/presentation/views/report_detail_screen.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_assign_crew_modal.dart';

class AdminReportDetailScreen extends ConsumerWidget {
  const AdminReportDetailScreen({
    super.key,
    required this.reportId,
    this.initialReport,
  });

  final String reportId;
  final ReportEntity? initialReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(authViewModelProvider.select((auth) => auth.user));
    final updated = ref.watch(
      adminReportsViewModelProvider.select(
        (state) =>
            state.reports.where((report) => report.id == reportId).firstOrNull,
      ),
    );
    return ReportDetailScreen(
      reportId: reportId,
      initialReport: updated ?? initialReport,
      bottomAction: (report, refresh) {
        if (admin == null || !admin.isAdmin || !admin.isActive) return null;
        if (report.collectionRouteId case final routeId?) {
          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.alt_route),
              label: const Text('Ver ruta de recolección'),
              onPressed: () => context.push(RouteNames.adminCollectionRouteLocation(routeId)),
            ),
          );
        }
        final isAssigned = report.status == ReportStatus.assigned;
        if (!isAssigned && report.status != ReportStatus.pending) return null;
        return SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Center(
            heightFactor: 1,
            child: SizedBox(
              width: 640,
              child: FilledButton.icon(
                icon: const Icon(Icons.assignment_ind_outlined),
                label: Text(
                  isAssigned ? 'Reasignar Personal' : 'Asignar Personal',
                ),
                onPressed: () async {
                  final saved = await AdminAssignCrewModal.show(
                    context: context,
                    report: report,
                    adminId: admin.id,
                    adminName: admin.name,
                  );
                  if (saved != true || !context.mounted) return;
                  await refresh();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${report.reportNumber} asignado correctamente.',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
