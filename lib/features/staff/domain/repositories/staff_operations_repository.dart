import '../entities/staff_operations.dart';

abstract interface class StaffOperationsRepository {
  Stream<String?> watchTeamId(String uid);
  Stream<StaffCrew?> watchCrew(String teamId);
  Stream<int> watchTeamTaskChanges(String teamId);
  Stream<StaffShift?> watchShift(String uid);
  Stream<List<StaffShiftEvent>> watchShiftEvents(String uid, String sessionId);
  Future<void> changeShift(String uid, StaffShiftStatus status);
}
