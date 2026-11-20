import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/staff/domain/entities/staff_operations.dart';
import 'package:ecoroute/features/staff/domain/entities/staff_task_entity.dart';
import 'package:ecoroute/features/staff/domain/usecases/order_staff_stops.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('El tiempo efectivo descuenta las pausas y se detiene al cerrar', () {
    StaffShiftEvent event(
      StaffShiftStatus status,
      int hour, [
      int minute = 0,
    ]) => StaffShiftEvent(
      status: status,
      changedAt: DateTime.utc(2026, 1, 1, hour, minute),
    );

    final history = [
      event(StaffShiftStatus.onDuty, 8),
      event(StaffShiftStatus.onBreak, 10),
      event(StaffShiftStatus.onDuty, 10, 30),
    ];
    final now = DateTime.utc(2026, 1, 1, 14);
    expect(
      activeShiftTime(history, now),
      const Duration(hours: 5, minutes: 30),
    );
    expect(
      activeShiftTime([...history, event(StaffShiftStatus.offDuty, 13)], now),
      const Duration(hours: 4, minutes: 30),
    );
  });

  test('La prioridad precede a la cercanía y la tarea activa va primero', () {
    StaffTaskEntity stop(
      String id,
      ReportPriority priority,
      double lng, {
      bool active = false,
    }) => StaffTaskEntity(
      id: id,
      reportNumber: id,
      citizenId: 'citizen',
      citizenName: 'Vecino',
      categoryName: 'Residuos',
      categoryIcon: '',
      description: '',
      priority: priority,
      status: active ? ReportStatus.inProgress : ReportStatus.assigned,
      address: '',
      latitude: -7.16,
      longitude: lng,
      reportImageUrls: const [],
      assignedAt: DateTime.utc(2026),
    );

    final tasks = [
      stop('far', ReportPriority.high, -78.56),
      stop('low', ReportPriority.low, -78.52),
      stop('near', ReportPriority.high, -78.53),
      stop('active', ReportPriority.low, -78.52, active: true),
    ];
    final ordered = orderStaffStops(tasks, origin: const LatLng(-7.16, -78.55));
    expect(ordered.map((task) => task.id), ['active', 'near', 'far', 'low']);
  });
}
