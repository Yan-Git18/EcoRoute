import 'package:latlong2/latlong.dart';

import '../../../citizen/domain/entities/report_entity.dart';
import '../entities/staff_task_entity.dart';

/// Atiende primero la parada iniciada y luego propone la más cercana de cada prioridad.
List<StaffTaskEntity> orderStaffStops(
  Iterable<StaffTaskEntity> tasks, {
  LatLng? origin,
}) {
  final active = tasks.where((task) => task.isInProgress).toList();
  final pending = tasks.where((task) => task.isPending).toList()
    ..sort((a, b) => a.assignedAt.compareTo(b.assignedAt));
  final result = [...active];
  final activeStop = active.lastOrNull;
  var position = activeStop != null && activeStop.hasReportLocation
      ? LatLng(activeStop.latitude, activeStop.longitude)
      : origin;
  const distance = Distance();

  for (final priority in ReportPriority.values.reversed) {
    final group = pending.where((task) => task.priority == priority).toList();
    while (group.isNotEmpty) {
      final from = position;
      var nearestIndex = 0;
      if (from != null) {
        var minimum = double.infinity;
        for (var i = 0; i < group.length; i++) {
          final task = group[i];
          if (!task.hasReportLocation) continue;
          final meters = distance(from, LatLng(task.latitude, task.longitude));
          if (meters < minimum) {
            minimum = meters;
            nearestIndex = i;
          }
        }
      }
      final next = group.removeAt(nearestIndex);
      result.add(next);
      if (next.hasReportLocation && position != null) {
        position = LatLng(next.latitude, next.longitude);
      }
    }
  }
  return result;
}
