import '../../domain/entities/staff_task_entity.dart';

/// Fixtures vacíos por defecto. En producción y operación real no se inyectan tareas de demostración.
/// Ubicación: `lib/features/staff/data/fixtures/staff_tasks_fixtures.dart`
/// Capa: Data (Fixtures)
abstract final class StaffTasksFixtures {
  static List<StaffTaskEntity> get defaultDemoTasks => const [];
}
