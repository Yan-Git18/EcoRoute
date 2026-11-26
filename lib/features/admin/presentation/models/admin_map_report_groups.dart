import 'dart:math';

import '../../../citizen/domain/entities/report_entity.dart';

/// Groups reports whose projected positions compete for the same tap area.
/// The first report anchors each marker so panning cannot change membership.
List<List<ReportEntity>> groupMapReports(
  Iterable<ReportEntity> reports, {
  required Point<double> Function(ReportEntity) project,
  required double spacing,
}) {
  final cells = <(int, int), List<_ReportGroup>>{};
  final groups = <_ReportGroup>[];

  for (final report in reports) {
    final point = project(report);
    final x = (point.x / spacing).floor();
    final y = (point.y / spacing).floor();
    _ReportGroup? closest;
    var closestDistance = spacing;

    for (var column = x - 1; column <= x + 1; column++) {
      for (var row = y - 1; row <= y + 1; row++) {
        for (final group in cells[(column, row)] ?? const <_ReportGroup>[]) {
          final distance = max(
            (group.anchor.x - point.x).abs(),
            (group.anchor.y - point.y).abs(),
          );
          if (distance <= closestDistance) {
            closest = group;
            closestDistance = distance;
          }
        }
      }
    }

    if (closest != null) {
      closest.reports.add(report);
    } else {
      final group = _ReportGroup(point, [report]);
      groups.add(group);
      (cells[(x, y)] ??= []).add(group);
    }
  }

  return [
    for (final group in groups) List<ReportEntity>.unmodifiable(group.reports),
  ];
}

class _ReportGroup {
  const _ReportGroup(this.anchor, this.reports);

  final Point<double> anchor;
  final List<ReportEntity> reports;
}
