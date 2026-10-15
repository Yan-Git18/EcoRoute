import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/report_filter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/eco_notification_button.dart';
import '../../../../core/widgets/eco_section_header.dart';
import '../../../../core/widgets/eco_status_summary_card.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../domain/entities/report_entity.dart';
import '../viewmodels/my_reports_viewmodel.dart';
import '../widgets/citizen_bottom_nav_bar.dart';
import '../widgets/citizen_hero_report_card.dart';
import '../widgets/citizen_quick_action_card.dart';

/// Pantalla principal (Dashboard) para el rol Ciudadano.
/// Capa: Presentation (Ciudadano)
class CitizenHomeScreen extends ConsumerWidget {
  const CitizenHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final userName = user?.name.trim();
    final firstName = (userName != null && userName.isNotEmpty)
        ? userName.split(' ').first
        : 'Carlos';

    final myReportsState = ref.watch(myReportsViewModelProvider);
    final pendingCount = myReportsState.reports
        .where((r) => r.status == ReportStatus.pending || r.status == ReportStatus.assigned)
        .length;
    final inProgressCount = myReportsState.reports
        .where((r) => r.status == ReportStatus.inProgress)
        .length;
    final resolvedCount = myReportsState.reports
        .where((r) => r.status == ReportStatus.resolved)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo_app.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'EcoRoute',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: EcoNotificationButton(
              onTap: () => _showNotificationsModal(context, ref, pendingCount, inProgressCount),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myReportsViewModelProvider.notifier).refresh(),
        color: const Color(0xFF0A5835),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // 1. Saludo personalizado y lema
              Text(
                '¡Hola, $firstName!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tu reporte ayuda a mantener una ciudad más limpia y saludable.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Tarjeta Hero destacada
              CitizenHeroReportCard(
                onTap: () => context.push(RouteNames.citizenCreateReport),
              ),
              const SizedBox(height: 24),

              // 3. Sección "Mis reportes" y resumen métrico de estados
              EcoSectionHeader(
                title: 'Mis reportes',
                actionText: 'Ver todos',
                onActionTap: () {
                  ref.read(myReportsViewModelProvider.notifier).setFilter(ReportFilter.all);
                  context.push(RouteNames.citizenMyReports);
                },
              ),
              const SizedBox(height: 12),
              EcoStatusSummaryCard(
                items: [
                  EcoStatusItem(
                    count: '$pendingCount',
                    label: 'Pendiente',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      ref.read(myReportsViewModelProvider.notifier).setFilter(ReportFilter.pending);
                      context.push(RouteNames.citizenMyReports);
                    },
                  ),
                  EcoStatusItem(
                    count: '$inProgressCount',
                    label: 'En proceso',
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      ref.read(myReportsViewModelProvider.notifier).setFilter(ReportFilter.inProgress);
                      context.push(RouteNames.citizenMyReports);
                    },
                  ),
                  EcoStatusItem(
                    count: '$resolvedCount',
                    label: 'Resueltos',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      ref.read(myReportsViewModelProvider.notifier).setFilter(ReportFilter.resolved);
                      context.push(RouteNames.citizenMyReports);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Sección "Acciones rápidas"
              const EcoSectionHeader(title: 'Acciones rápidas'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CitizenQuickActionCard(
                      icon: Icons.place_rounded,
                      iconBgColor: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF047857),
                      title: 'Mapa',
                      subtitle: 'Ver incidencias\ncercanas',
                      onTap: () => context.push(RouteNames.citizenMap),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CitizenQuickActionCard(
                      icon: Icons.assignment_outlined,
                      iconBgColor: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Mis reportes',
                      subtitle: 'Historial y estado\n',
                      onTap: () {
                        ref.read(myReportsViewModelProvider.notifier).setFilter(ReportFilter.all);
                        context.push(RouteNames.citizenMyReports);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CitizenBottomNavBar(currentIndex: 0),
    );
  }

  void _showNotificationsModal(
    BuildContext context,
    WidgetRef ref,
    int pending,
    int inProgress,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                      'Notificaciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
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
                          Icons.info_outline_rounded,
                          color: Color(0xFF047857),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          (pending + inProgress > 0)
                              ? 'Tienes ${pending + inProgress} reporte(s) en seguimiento activo.'
                              : 'No tienes incidencias pendientes en este momento.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      ref.read(myReportsViewModelProvider.notifier).setFilter(ReportFilter.all);
                      context.push(RouteNames.citizenMyReports);
                    },
                    child: const Text('Ver todos los reportes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
