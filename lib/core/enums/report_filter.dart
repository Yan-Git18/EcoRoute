enum ReportFilter {
  all('Todos'),
  pending('Pendientes'),
  inProgress('En proceso'),
  resolved('Resueltos');

  final String label;
  const ReportFilter(this.label);
}
