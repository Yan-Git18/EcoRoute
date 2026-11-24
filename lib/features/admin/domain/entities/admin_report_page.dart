abstract interface class AdminReportCursor {}

class AdminReportPage<T> {
  const AdminReportPage(this.items, {this.nextCursor});

  static const pageSize = 30;

  final List<T> items;
  final AdminReportCursor? nextCursor;
}

typedef AdminReportTotals = ({
  int total,
  int pending,
  int assigned,
  int inProgress,
  int resolved,
});
