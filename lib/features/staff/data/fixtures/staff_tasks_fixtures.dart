import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/staff_task_entity.dart';

/// Fixtures y datos de demostración centralizados para el personal de limpieza.
///
/// Principio DRY: Evita la duplicación de datos de prueba y visualización inicial
/// en múltiples pantallas (StaffHomeScreen, StaffTasksScreen, StaffRouteMapScreen).
/// Ubicación: `lib/features/staff/data/fixtures/staff_tasks_fixtures.dart`
/// Capa: Data (Fixtures)
abstract final class StaffTasksFixtures {
  static StaffTaskEntity _task({
    required String id,
    required String num,
    required String cat,
    required String icon,
    required String desc,
    required ReportPriority prio,
    required String addr,
    required double lat,
    required double lng,
    ReportStatus status = ReportStatus.pending,
    int hoursAgo = 1,
  }) {
    return StaffTaskEntity(
      id: id,
      reportNumber: num,
      citizenId: 'c-$id',
      citizenName: 'Vecino Ciudadano',
      categoryName: cat,
      categoryIcon: icon,
      description: desc,
      priority: prio,
      status: status,
      address: addr,
      latitude: lat,
      longitude: lng,
      reportImageUrls: const [],
      assignedAt: DateTime.now().subtract(Duration(hours: hoursAgo)),
    );
  }

  static List<StaffTaskEntity> get defaultDemoTasks => [
    _task(
      id: 'task-demo-1',
      num: '#0102',
      cat: 'Contenedor lleno',
      icon: 'delete_outline_rounded',
      desc: 'Contenedor saturado en Jr. Del Comercio.',
      prio: ReportPriority.high,
      addr: 'Av. Los Próceres 452',
      lat: -7.1580,
      lng: -78.5180,
      hoursAgo: 1,
    ),
    _task(
      id: 'task-demo-2',
      num: '#0103',
      cat: 'Residuos en vía pública',
      icon: 'cleaning_services_rounded',
      desc: 'Restos de poda y bolsas en vereda.',
      prio: ReportPriority.medium,
      addr: 'Jr. Amazonas 120',
      lat: -7.1565,
      lng: -78.5160,
      hoursAgo: 2,
    ),
    _task(
      id: 'task-demo-3',
      num: '#0104',
      cat: 'Punto de recolección',
      icon: 'recycling_rounded',
      desc: 'Limpieza periódica de contenedores verdes.',
      prio: ReportPriority.low,
      addr: 'Parque Central',
      lat: -7.1578,
      lng: -78.5175,
      hoursAgo: 3,
    ),
    _task(
      id: 'task-demo-4',
      num: '#0105',
      cat: 'Acumulación de maleza',
      icon: 'delete_sweep_rounded',
      desc: 'Restos vegetales en vereda.',
      prio: ReportPriority.medium,
      addr: 'Av. Las Palmas 890',
      lat: -7.1610,
      lng: -78.5210,
      hoursAgo: 4,
    ),
    _task(
      id: 'task-demo-5',
      num: '#0101',
      cat: 'Desborde de basura',
      icon: 'delete_outline_rounded',
      desc: 'Acumulación crítica reportada para recolección con camión.',
      prio: ReportPriority.high,
      status: ReportStatus.pending,
      addr: 'Calle Los Pinos 88',
      lat: -7.1520,
      lng: -78.5130,
      hoursAgo: 5,
    ),
    ...List.generate(
      6,
      (i) => _task(
        id: 'task-res-$i',
        num: '#009${i + 1}',
        cat: 'Limpieza de zona',
        icon: 'check_circle_outline_rounded',
        desc: 'Limpieza completada y validada.',
        prio: ReportPriority.low,
        status: ReportStatus.resolved,
        addr: 'Sector ${i + 1}',
        lat: -7.1600 - (i * 0.001),
        lng: -78.5150 - (i * 0.001),
        hoursAgo: (i + 1) * 24,
      ),
    ),
  ];
}
