import '../../../citizen/domain/entities/report_entity.dart';

extension AdminMapReportStatus on ReportEntity {
  bool get isOpenForOperations => switch (status) {
    ReportStatus.pending || ReportStatus.assigned || ReportStatus.inProgress => true,
    ReportStatus.resolved || ReportStatus.cancelled => false,
  };

  bool get isReservedForRoute =>
      status == ReportStatus.pending && (collectionRouteId?.isNotEmpty ?? false);

  bool get isAssignedForOperations =>
      status == ReportStatus.assigned ||
      status == ReportStatus.inProgress ||
      isReservedForRoute;
}
