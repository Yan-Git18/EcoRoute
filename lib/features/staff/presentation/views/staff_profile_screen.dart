import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/media_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/profile/profile_widgets.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../domain/entities/staff_operations.dart';
import '../viewmodels/staff_home_viewmodel.dart';
import '../viewmodels/staff_operations_providers.dart';
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
  bool _priorityNotificationsEnabled = true;
  bool _taskAssignedNotificationsEnabled = true;
  bool _shiftAlertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    final displayName = user?.name.isNotEmpty == true ? user!.name : 'Personal de Limpieza';
    final teamSubtitle = staffCrewName(ref.watch(staffCrewProvider));

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
                child: ClipOval(
                  child: MediaImage(
                    location: user?.photoUrl,
                    placeholder: const Icon(
                      Icons.engineering_rounded,
                      size: 58,
                      color: Color(0xFF047857),
                    ),
                  ),
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
      bottomNavigationBar: const StaffBottomNavBar(currentIndex: 4),
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
    final staffName = user?.name.isNotEmpty == true ? user!.name : 'Personal de Limpieza';
    final staffEmail = user?.email.isNotEmpty == true ? user!.email : '';
    final phone = user?.phoneNumber ?? 'Sin teléfono registrado';

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
    final email = user?.email.isNotEmpty == true ? user!.email : '';
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

  void _showStatsModal(BuildContext context) {
    var saving = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => Consumer(
          builder: (context, ref, _) {
            final staff = ref.watch(authViewModelProvider).user;
            final crewState = ref.watch(staffCrewProvider);
            final crew = crewState.asData?.value;
            final taskState = ref.watch(staffHomeViewModelProvider);
            final shiftState = staff == null
                ? const AsyncData<StaffShift?>(null)
                : ref.watch(staffShiftProvider(staff.id));
            final shift = shiftState.asData?.value;
            final events = staff != null && shift != null
                ? ref.watch(staffShiftEventsProvider((staff.id, shift.sessionId))).asData?.value
                : null;
            final now = shift?.status == StaffShiftStatus.onDuty
                ? ref.watch(staffShiftClockProvider).asData?.value ?? DateTime.now()
                : DateTime.now();
            final worked = events == null || events.isEmpty ? null : activeShiftTime(events, now);
            final tasksAvailable = !taskState.isLoading && taskState.loadErrorMessage == null;

            Future<void> changeShift() async {
              if (staff == null || saving) return;
              final repository = ref.read(staffOperationsRepositoryProvider);
              final currentStatus = shift?.status ?? StaffShiftStatus.offDuty;
              final next = await StaffShiftStatusModal.show(
                context: context,
                currentStatus: currentStatus,
              );
              if (!context.mounted || next == null || next == currentStatus) return;
              setSheetState(() => saving = true);
              try {
                await repository.changeShift(staff.id, next);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo guardar el estado del turno.')),
                  );
                }
              } finally {
                if (context.mounted) setSheetState(() => saving = false);
              }
            }

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mis estadísticas',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Cerrar estadísticas',
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.schedule),
                        title: const Text('Estado de Turno'),
                        subtitle: Text(switch (shiftState) {
                          AsyncData() => shift?.status.label ?? 'Sin turno registrado',
                          AsyncError() => 'Estado no disponible',
                          _ => 'Cargando turno…',
                        }),
                        trailing: OutlinedButton(
                          onPressed: staff == null || saving || shiftState is! AsyncData
                              ? null
                              : changeShift,
                          child: Text(saving ? 'Guardando…' : 'Cambiar'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatMiniCard(
                            title: 'Resueltas Hoy',
                            value: tasksAvailable ? '${taskState.resolvedOn(now, staff?.id)}' : '—',
                            color: const Color(0xFF047857),
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatMiniCard(
                            title: 'Por Atender',
                            value: tasksAvailable ? '${taskState.pendingCount}' : '—',
                            color: const Color(0xFFB45309),
                            icon: Icons.pending_actions_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _StatMiniCard(
                      title: 'Tiempo efectivo del turno',
                      value: worked == null
                          ? '—'
                          : '${worked.inHours} h ${worked.inMinutes % 60} min',
                      color: const Color(0xFF2563EB),
                      icon: Icons.timer_outlined,
                    ),
                    const SizedBox(height: 16),
                    _SmallInfoRow(
                      icon: Icons.groups_rounded,
                      iconColor: const Color(0xFF047857),
                      title: 'Cuadrilla',
                      subtitle: staffCrewName(crewState),
                    ),
                    const Divider(height: 16),
                    _SmallInfoRow(
                      icon: Icons.local_shipping_rounded,
                      iconColor: const Color(0xFF2563EB),
                      title: 'Unidad vehicular',
                      subtitle: crew?.vehicleLabel ?? 'Vehículo sin registrar',
                    ),
                    const Divider(height: 16),
                    _SmallInfoRow(
                      icon: Icons.map_rounded,
                      iconColor: const Color(0xFFB45309),
                      title: 'Zona de cobertura',
                      subtitle: crew?.zone ?? 'Zona sin registrar',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final staffState = ref.watch(staffHomeViewModelProvider);
          final staffId = ref.watch(authViewModelProvider.select((auth) => auth.user?.id));
          final resolvedTasks = staffState.resolvedBy(staffId).toList()
            ..sort((a, b) {
              final first = a.resolvedAt;
              final second = b.resolvedAt;
              if (first != null && second != null) return second.compareTo(first);
              if (first == null && second == null) return b.assignedAt.compareTo(a.assignedAt);
              return first == null ? 1 : -1;
            });
          final recent = resolvedTasks.take(3).toList();
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
                if (staffState.isLoading)
                  const LinearProgressIndicator()
                else if (staffState.loadErrorMessage case final error?)
                  Text(error)
                else if (recent.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.history_rounded, size: 36, color: Color(0xFF94A3B8)),
                        SizedBox(height: 8),
                        Text(
                          'Aún no hay tareas completadas registradas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (int i = 0; i < recent.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _TaskHistoryItem(
                      folio: recent[i].reportNumber,
                      category: recent[i].categoryName,
                      address: recent[i].address,
                      time: recent[i].resolvedAt == null
                          ? 'Sin fecha de cierre registrada'
                          : DateFormat('dd/MM/yyyy HH:mm').format(recent[i].resolvedAt!.toLocal()),
                      isCompleted: true,
                    ),
                  ],
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
      ),
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
