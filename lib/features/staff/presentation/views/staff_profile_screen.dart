import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/profile/profile_widgets.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/staff_home_viewmodel.dart';
import '../widgets/staff_bottom_nav_bar.dart';
import '../widgets/staff_shift_status_modal.dart';

/// Pantalla rediseñada de Perfil del Personal de Limpieza.
///
/// Adopta el diseño limpio y moderno de la tarjeta de perfil con las opciones operativas:
/// - Mis estadísticas (con desglose de turno, paradas resueltas y rendimiento)
/// - Historial de tareas
/// - Configuración (con Mis datos, Cambiar contraseña y Notificaciones)
/// - Ayuda y soporte
/// - Cerrar sesión (en rojo con diálogo de confirmación)
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
  bool _taskAssignedNotificationsEnabled = true;
  bool _shiftAlertsEnabled = true;

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

    final displayName = user?.name.isNotEmpty == true ? user!.name : 'Carlos Mendoza';
    final teamSubtitle = user?.teamId != null && user!.teamId!.isNotEmpty
        ? 'Equipo de limpieza #${user.teamId}'
        : 'Equipo de limpieza #03';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Mi perfil',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // 1. Avatar circular del operario con fondo verde suave
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.engineering_rounded,
                            size: 58,
                            color: Color(0xFF047857),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.engineering_rounded,
                        size: 58,
                        color: Color(0xFF047857),
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Nombre del operario
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),

            // 3. Subtítulo: Equipo de limpieza
            Text(
              teamSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Tarjeta blanca con opciones principales del personal
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Mis estadísticas
                  EcoProfileMenuItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Mis estadísticas',
                    onTap: () => _showStatsModal(context),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    endIndent: 16,
                    color: Color(0xFFF1F5F9),
                  ),

                  // Historial de tareas
                  EcoProfileMenuItem(
                    icon: Icons.event_note_rounded,
                    title: 'Historial de tareas',
                    onTap: () => _showTaskHistoryModal(context),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    endIndent: 16,
                    color: Color(0xFFF1F5F9),
                  ),

                  // Configuración
                  EcoProfileMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Configuración',
                    onTap: () => _showSettingsModal(context, ref, user),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    endIndent: 16,
                    color: Color(0xFFF1F5F9),
                  ),

                  // Ayuda y soporte
                  EcoProfileMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Ayuda y soporte',
                    onTap: () => _showSupportModal(context),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    endIndent: 16,
                    color: Color(0xFFF1F5F9),
                  ),

                  // Cerrar sesión (en rojo con ícono a juego)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      onTap: () => _confirmLogout(context, ref),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFEF4444),
                              size: 22,
                            ),
                            SizedBox(width: 14),
                            Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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

  // --- Modales funcionales interactivos ---

  /// Modal de Configuración que contiene las opciones solicitadas:
  /// - Mis datos
  /// - Cambiar contraseña
  /// - Notificaciones
  /// (Sin "Acerca de EcoRoute" y sin "Cerrar sesión")
  void _showSettingsModal(BuildContext context, WidgetRef ref, UserEntity? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Configuración',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 1. Mis datos
                    EcoProfileMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Mis datos',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showMyDataModal(context, user);
                      },
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 52,
                      endIndent: 16,
                      color: Color(0xFFF1F5F9),
                    ),

                    // 2. Cambiar contraseña
                    EcoProfileMenuItem(
                      icon: Icons.lock_outline_rounded,
                      title: 'Cambiar contraseña',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showChangePasswordModal(context, ref, user);
                      },
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 52,
                      endIndent: 16,
                      color: Color(0xFFF1F5F9),
                    ),

                    // 3. Notificaciones
                    EcoProfileMenuItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notificaciones',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showNotificationsModal(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Modal con los datos del personal de limpieza
  void _showMyDataModal(BuildContext context, UserEntity? user) {
    final staffName = user?.name.isNotEmpty == true ? user!.name : 'Carlos Mendoza';
    final staffEmail = user?.email.isNotEmpty == true ? user!.email : 'carlos.mendoza@ecoroute.com';
    final phone = user?.phoneNumber ?? '+51 988 123 456';

    ProfileDataModal.show(
      context,
      name: staffName,
      email: staffEmail,
      phone: phone,
      roleLabel: 'Personal de Limpieza',
    );
  }

  /// Modal para cambiar contraseña enviando correo de recuperación
  void _showChangePasswordModal(
    BuildContext context,
    WidgetRef ref,
    UserEntity? user,
  ) {
    final email = user?.email.isNotEmpty == true ? user!.email : 'carlos.mendoza@ecoroute.com';
    ProfileChangePasswordModal.show(context, ref, email: email);
  }

  /// Modal de preferencias de notificaciones operativas
  void _showNotificationsModal(BuildContext context) {
    ProfileNotificationsModal.show(
      context,
      options: [
        NotificationOptionItem(
          title: 'Alertas de paradas prioritarias',
          subtitle: 'Notificar cuando se asigne un desborde urgente en ruta.',
          initialValue: _priorityNotificationsEnabled,
          onChanged: (val) => _priorityNotificationsEnabled = val,
        ),
        NotificationOptionItem(
          title: 'Asignación de nuevas paradas',
          subtitle: 'Avisar cuando se agreguen paradas al circuito actual.',
          initialValue: _taskAssignedNotificationsEnabled,
          onChanged: (val) => _taskAssignedNotificationsEnabled = val,
        ),
        NotificationOptionItem(
          title: 'Avisos de inicio y fin de turno',
          subtitle: 'Recordatorios del horario de entrada y relevo de cuadrilla.',
          initialValue: _shiftAlertsEnabled,
          onChanged: (val) => _shiftAlertsEnabled = val,
        ),
      ],
    );
  }

  /// Modal interactivo de estadísticas de desempeño del operario
  void _showStatsModal(BuildContext context) {
    final staffState = ref.watch(staffHomeViewModelProvider);
    final totalResolved = staffState.resolvedCount > 0 ? staffState.resolvedCount : 6;
    final totalPending = staffState.pendingCount > 0 ? staffState.pendingCount : 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mis estadísticas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Estado de turno con botón interactivo de cambio
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getShiftStatusColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estado de Turno',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _shiftStatus,
                                style: TextStyle(
                                  fontSize: 14,
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
                              onStatusSelected: (status) {
                                setState(() => _shiftStatus = status);
                                setModalState(() {});
                              },
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0A5835),
                            side: const BorderSide(color: Color(0xFF0A5835), width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          child: const Text(
                            'Cambiar',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Métricas clave de rendimiento
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
                      const SizedBox(width: 10),
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
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Tasa a Tiempo',
                          value: '98%',
                          color: Color(0xFF2563EB),
                          icon: Icons.speed_rounded,
                        ),
                      ),
                      SizedBox(width: 10),
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
                  const SizedBox(height: 16),

                  // Asignación de Cuadrilla y Unidad
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      children: [
                        _SmallInfoRow(
                          icon: Icons.groups_rounded,
                          iconColor: Color(0xFF047857),
                          title: 'Personal Asignado',
                          subtitle: 'Cuadrilla Zona Norte (Turno Diurno)',
                        ),
                        Divider(height: 16, color: Color(0xFFE2E8F0)),
                        _SmallInfoRow(
                          icon: Icons.local_shipping_rounded,
                          iconColor: Color(0xFF2563EB),
                          title: 'Unidad Vehicular',
                          subtitle: 'Camión Recolector #04 • Placa ECR-882',
                        ),
                        Divider(height: 16, color: Color(0xFFE2E8F0)),
                        _SmallInfoRow(
                          icon: Icons.map_rounded,
                          iconColor: Color(0xFFD97706),
                          title: 'Zona de Cobertura',
                          subtitle: 'Sector 1 y 2 • Cajamarca',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Modal con historial resumido de tareas recientes
  void _showTaskHistoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Historial de tareas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Registro de las paradas y recolecciones completadas recientemente.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              const _TaskHistoryItem(
                folio: '#0102',
                category: 'Contenedor lleno',
                address: 'Jr. Del Comercio 620, Cajamarca',
                time: 'Hace 1 hora',
                isCompleted: true,
              ),
              const SizedBox(height: 8),
              const _TaskHistoryItem(
                folio: '#0103',
                category: 'Residuos en vía pública',
                address: 'Jr. Amazonas 450, Cajamarca',
                time: 'Hace 2 horas',
                isCompleted: true,
              ),
              const SizedBox(height: 8),
              const _TaskHistoryItem(
                folio: '#0104',
                category: 'Punto de recolección',
                address: 'Plaza de Armas de Cajamarca',
                time: 'Hace 3 horas',
                isCompleted: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go(RouteNames.staffTasks);
                  },
                  icon: const Icon(Icons.assignment_rounded, size: 20),
                  label: const Text(
                    'Ver todas las tareas en el panel',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A5835),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Modal de asistencia técnica y ayuda operativa
  void _showSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ayuda y soporte operativo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Canales de asistencia y comunicación para personal en campo.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              const _SupportTile(
                icon: Icons.radio_rounded,
                iconColor: Color(0xFF0A5835),
                title: 'Canal de Radio Municipal',
                subtitle: 'Frecuencia operativa #04 (Central Cajamarca)',
              ),
              const SizedBox(height: 10),
              const _SupportTile(
                icon: Icons.phone_in_talk_rounded,
                iconColor: Color(0xFF2563EB),
                title: 'Teléfono de Despacho',
                subtitle: '+51 076 362 222 • Anexo 104',
              ),
              const SizedBox(height: 10),
              const _SupportTile(
                icon: Icons.build_circle_rounded,
                iconColor: Color(0xFFD97706),
                title: 'Auxilio Mecánico de Cuadrilla',
                subtitle: 'Soporte técnico para camión recolector en ruta',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A5835),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Confirmación de cierre de sesión
  void _confirmLogout(BuildContext context, WidgetRef ref) {
    ProfileLogoutDialog.show(
      context,
      onConfirm: () => ref.read(authViewModelProvider.notifier).logout(),
    );
  }
}

/// Tarjeta pequeña de métricas
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                    fontSize: 16,
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

/// Fila pequeña informativa de asignación
class _SmallInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SmallInfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Item para el historial de tareas
class _TaskHistoryItem extends StatelessWidget {
  final String folio;
  final String category;
  final String address;
  final String time;
  final bool isCompleted;

  const _TaskHistoryItem({
    required this.folio,
    required this.category,
    required this.address,
    required this.time,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF047857),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$folio • $category',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila para elementos de ayuda y soporte
class _SupportTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SupportTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
