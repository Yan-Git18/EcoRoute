class StaffCrew {
  const StaffCrew({this.name, this.zone, this.vehicleCode, this.vehiclePlate});

  final String? name;
  final String? zone;
  final String? vehicleCode;
  final String? vehiclePlate;

  String? get vehicleLabel {
    final details = [
      if (vehicleCode case final code?) code,
      if (vehiclePlate case final plate?) 'Placa $plate',
    ];
    return details.isEmpty ? null : details.join(' • ');
  }
}

enum StaffShiftStatus {
  onDuty('on_duty', 'En turno'),
  onBreak('on_break', 'En descanso'),
  offDuty('off_duty', 'Fuera de servicio');

  const StaffShiftStatus(this.value, this.label);

  final String value;
  final String label;

  static StaffShiftStatus fromValue(Object? value) =>
      values.firstWhere((status) => status.value == value);

  bool canChangeTo(StaffShiftStatus next) =>
      this != next && (this != offDuty || next == onDuty);
}

class StaffShift {
  const StaffShift({required this.status, required this.sessionId});

  final StaffShiftStatus status;
  final String sessionId;
}

class StaffShiftEvent {
  const StaffShiftEvent({required this.status, required this.changedAt});

  final StaffShiftStatus status;
  final DateTime changedAt;
}

Duration activeShiftTime(List<StaffShiftEvent> history, DateTime now) {
  final events = [...history]
    ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
  var total = Duration.zero;
  for (var i = 0; i < events.length; i++) {
    final event = events[i];
    if (event.status != StaffShiftStatus.onDuty) continue;
    final end = i + 1 < events.length ? events[i + 1].changedAt : now;
    if (end.isAfter(event.changedAt)) total += end.difference(event.changedAt);
  }
  return total;
}
