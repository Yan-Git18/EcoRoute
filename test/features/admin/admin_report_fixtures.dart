import 'package:ecoroute/features/admin/domain/entities/admin_report_page.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';

AdminReportTotals totalsForReports(List<ReportEntity> reports) {
  int count(ReportStatus status) => reports.where((report) => report.status == status).length;
  return (
    total: reports.length,
    pending: count(ReportStatus.pending),
    assigned: count(ReportStatus.assigned),
    inProgress: count(ReportStatus.inProgress),
    resolved: count(ReportStatus.resolved),
  );
}
