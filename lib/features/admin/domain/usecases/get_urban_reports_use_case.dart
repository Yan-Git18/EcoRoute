import '../../../../core/geo/cajamarca_urban_zones.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../entities/admin_report_page.dart';
import '../repositories/admin_repository.dart';

class GetUrbanReportsUseCase {
  const GetUrbanReportsUseCase(this._repository);

  final AdminRepository _repository;

  Future<Map<CajamarcaZone, List<ReportEntity>>> call() async {
    final reports = <CajamarcaZone, List<ReportEntity>>{};
    final seen = <String>{};
    AdminReportCursor? cursor;

    do {
      final page = (await _repository.getReportsPage(after: cursor)).fold(
        onSuccess: (page) => page,
        onFailure: (failure) => throw StateError(failure.message),
      );

      for (final report in page.items) {
        if (!seen.add(report.id)) continue;
        final zone = CajamarcaUrbanZones.zoneAt(
          report.latitude,
          report.longitude,
        );
        if (zone != null) (reports[zone] ??= []).add(report);
      }
      cursor = page.nextCursor;
    } while (cursor != null);

    return Map.unmodifiable({
      for (final entry in reports.entries)
        entry.key: List<ReportEntity>.unmodifiable(entry.value),
    });
  }
}
