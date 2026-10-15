import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/staff_home_viewmodel.dart';
import '../widgets/staff_bottom_nav_bar.dart';
import '../widgets/staff_shift_status_modal.dart';

/// Pantalla completa de Perfil del Personal / Operario de Cuadrilla (Fase 3).
///
/// Presenta la ficha de identidad del operario, asignación de cuadrilla y vehículo,
/// control interactivo de turno, métricas de desempeño y opciones de cierre de sesión seguro.
///
/// Ubicación: `lib/features/staff/presentation/views/staff_profile_screen.dart`
/// Capa: Presentation (Personal)
class StaffProfileScreen extends ConsumerStatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  ConsumerState<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen> {
  String _shiftStatus = 'En turno';
  bool _priorityNotificationsEnabled = true;

  Color _getShiftStatusColor() {
    switch (_shiftStatus) {
      case 'En turno':
        return const Color(0xFF10B981); // Verde activo
      case 'En descanso':
        return const Color(0xFFF59E0B); // Ámbar descanso
      default:
        return const Color(0xFF64748B); // Gris fuera de servicio
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final staffName = user?.name ?? 'Mario Limpieza';
    final staffEmail = user?.email ?? 'mario@ecoroute.com';

    final staffState = ref.watch(staffHomeViewModelProvider);
    final totalResolved = staffState.resolvedCount > 0 ? staffState.resolvedCount : 6;
    final totalPending = staffState.pendingCount > 0 ? staffState.pendingCount : 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.staffHome);
            }
          },
        ),
        centerTitle: true,
        title: const Text(
          'Perfil Operativo',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tarjeta Principal de Identidad del Operario
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(0xFFDCFCE7),
                        child: Text(
                          staffName.isNotEmpty ? staffName[0].toUpperCase() : 'M',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _getShiftStatusColor(),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    staffName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    staffEmail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A5835).withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Cuadrilla de Campo',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A5835),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Legajo #OP-2048',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Control Interactivo del Estado de Turno
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _getShiftStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estado de Turno',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _shiftStatus,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _getShiftStatusColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      StaffShiftStatusModal.show(
                        context: context,
                        currentStatus: _shiftStatus,
                        onStatusSelected: (status) => setState(() => _shiftStatus = status),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0A5835),
                      side: const BorderSide(color: Color(0xFF0A5835), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text(
                      'Cambiar',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Tarjeta de Asignación de Cuadrilla y Unidad Vehicular
            const Text(
              'Asignación Operativa',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.groups_rounded,
                    iconColor: const Color(0xFF047857),
                    title: 'Personal Asignado',
                    subtitle: 'Cuadrilla Zona Norte (Turno Diurno)',
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
                  _InfoTile(
                    icon: Icons.local_shipping_rounded,
                    iconColor: const Color(0xFF2563EB),
                    title: 'Unidad Vehicular',
                    subtitle: 'Camión Recolector #04 • Placa ECR-882',
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
                  _InfoTile(
                    icon: Icons.map_rounded,
                    iconColor: const Color(0xFFD97706),
                    title: 'Zona de Cobertura',
                    subtitle: 'Sector 1 y 2 • Distrito Central',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Métricas de Desempeño Acumulado
            const Text(
              'Rendimiento en Campo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatMiniCard(
                    title: 'Resueltas Hoy',
                    value: '$totalResolved',
                    color: const Color(0xFF047857),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatMiniCard(
                    title: 'Por Atender',
                    value: '$totalPending',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.pending_actions_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: _StatMiniCard(
                    title: 'Tasa a Tiempo',
                    value: '98%',
                    color: Color(0xFF2563EB),
                    icon: Icons.speed_rounded,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatMiniCard(
                    title: 'Horas en Turno',
                    value: '7.5 h',
                    color: Color(0xFF7C3AED),
                    icon: Icons.timer_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Ajustes y Soporte Municipal
            const Text(
              'Ajustes y Asistencia',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _priorityNotificationsEnabled,
                    onChanged: (val) => setState(() => _priorityNotificationsEnabled = val),
                    activeThumbColor: const Color(0xFF0A5835),
                    title: const Text(
                      'Alertas de paradas prioritarias',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Notificar cuando se asigne un desborde urgente',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A5835).withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF0A5835), size: 20),
                    ),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    title: const Text(
                      'Central de Operaciones',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Radio y asistencia técnica de cuadrilla',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Comunícate con la central vía canal de radio #04.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. Botón de Cerrar Sesión con Confirmación
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, ref),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                label: const Text(
                  'Cerrar Sesión Operativa',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: 3,
        onTabSelected: (index) {
          if (index == 0) {
            context.go(RouteNames.staffHome);
          } else if (index == 1) {
            context.go(RouteNames.staffRouteMap);
          } else if (index == 2) {
            context.go(RouteNames.staffTasks);
          } else if (index == 3) {
            // Ya en perfil
          }
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Finalizar sesión?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'Asegúrate de haber registrado todas las evidencias de paradas atendidas antes de salir.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authViewModelProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatMiniCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
