import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/eco_notification_button.dart';
import '../../../../core/widgets/profile/profile_widgets.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/admin_report_page.dart';
import '../viewmodels/admin_reports_state.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_account_drawer.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/admin_load_notice.dart';

const _panelBackground = Color(0xFFF3F6F3);
const _panelBorder = Color(0xFFDDE7DF);
const _panelHeading = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 20,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.4,
);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    final user = auth.user;
    final state = ref.watch(adminReportsViewModelProvider);
    final viewModel = ref.read(adminReportsViewModelProvider.notifier);
    final totals = state.totals;
    final pendingReports = state.reports.where(
      (report) => report.status == ReportStatus.pending,
    );
    final featuredReport =
        pendingReports
            .where((report) => report.priority == ReportPriority.high)
            .firstOrNull ??
        pendingReports.firstOrNull;

    void openPendingReports() {
      viewModel.setSearchQuery('');
      viewModel.setFilter(AdminReportFilter.pending);
      context.push(RouteNames.adminReports);
    }

    return Scaffold(
      backgroundColor: _panelBackground,
      drawer: AdminAccountDrawer(
        user: user,
        isSigningOut: auth.isLoading,
        onViewAccount: user == null
            ? null
            : () => ProfileDataModal.show(
                context,
                name: user.name,
                email: user.email,
                phone: user.phoneNumber ?? 'Sin registrar',
                roleLabel: user.role.displayName,
              ),
        onChangePassword: user == null || user.email.trim().isEmpty
            ? null
            : () => ProfileChangePasswordModal.show(
                context,
                ref,
                email: user.email,
              ),
        onLogout: () => ProfileLogoutDialog.show(
          context,
          onConfirm: ref.read(authViewModelProvider.notifier).logout,
        ),
      ),
      appBar: AppBar(
        backgroundColor: _panelBackground,
        foregroundColor: AppColors.textPrimary,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leadingWidth: 68,
        leading: Builder(
          builder: (context) => Center(
            child: IconButton.outlined(
              tooltip: 'Abrir menú de cuenta',
              onPressed: Scaffold.of(context).openDrawer,
              icon: const Icon(Icons.menu_rounded),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(44),
                foregroundColor: AppColors.forest,
                backgroundColor: Colors.white,
                side: const BorderSide(color: _panelBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        titleSpacing: 0,
        title: const Text('Panel municipal', style: _panelHeading),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: EcoNotificationButton(
              tooltip: 'Reportes pendientes',
              onTap: openPendingReports,
              hasUnread: (totals?.pending ?? 0) > 0,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdminLoadNotice(state: state, onRetry: viewModel.refresh),
                    if (totals != null || state.hasLoadedReports) ...[
                      if (state.isLoading ||
                          state.reportsLoadFailed ||
                          state.crewsLoadFailed ||
                          state.totalsLoadFailed)
                        const SizedBox(height: 12),
                      _PendingReportsSummary(
                        count: totals?.pending,
                        onPressed: openPendingReports,
                      ),
                      const SizedBox(height: 10),
                      _ReportMetrics(totals: totals),
                      const SizedBox(height: 20),
                    ],
                    if (featuredReport != null) ...[
                      const Text('Por atender', style: _panelHeading),
                      const SizedBox(height: 8),
                      _FeaturedReportCard(
                        report: featuredReport,
                        onPressed: () => context.push(
                          RouteNames.adminReportLocation(featuredReport.id),
                          extra: featuredReport,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const Text('Operación', style: _panelHeading),
                    const SizedBox(height: 8),
                    _OperationLinks(
                      onOpenFleet: () => context.push(RouteNames.adminFleet),
                      onOpenStaff: () => context.push(RouteNames.adminStaff),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 0),
    );
  }
}

class _PendingReportsSummary extends StatelessWidget {
  const _PendingReportsSummary({required this.count, required this.onPressed});

  final int? count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reportes pendientes',
              style: TextStyle(
                color: Color(0xFFC2EFDB),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Text(
                    count?.toString() ?? '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -1.5,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Ver pendientes'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      backgroundColor: AppColors.mint,
                      foregroundColor: AppColors.forest,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportMetrics extends StatelessWidget {
  const _ReportMetrics({required this.totals});

  final AdminReportTotals? totals;

  @override
  Widget build(BuildContext context) {
    final counts = totals;
    return _PanelSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack =
              constraints.maxWidth < 250 ||
              MediaQuery.textScalerOf(context).scale(13) > 17;
          final metrics = [
            _Metric(
              label: 'Total',
              value: counts?.total,
              color: AppColors.textPrimary,
            ),
            _Metric(
              label: 'En proceso',
              value: counts == null
                  ? null
                  : counts.inProgress + counts.assigned,
              color: const Color(0xFF1D4ED8),
            ),
            _Metric(
              label: 'Resueltos',
              value: counts?.resolved,
              color: AppColors.primaryDark,
            ),
          ];

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: metrics,
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: metrics[0]),
                const VerticalDivider(
                  width: 1,
                  color: _panelBorder,
                  indent: 10,
                  endIndent: 10,
                ),
                Expanded(child: metrics[1]),
                const VerticalDivider(
                  width: 1,
                  color: _panelBorder,
                  indent: 10,
                  endIndent: 10,
                ),
                Expanded(child: metrics[2]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value?.toString() ?? '—',
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedReportCard extends StatelessWidget {
  const _FeaturedReportCard({required this.report, required this.onPressed});

  final ReportEntity report;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final highPriority = report.priority == ReportPriority.high;
    return _PanelSurface(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: Icon(
          highPriority
              ? Icons.priority_high_rounded
              : Icons.assignment_outlined,
          color: highPriority ? const Color(0xFF9A3412) : AppColors.forest,
          semanticLabel: highPriority ? 'Prioridad alta' : null,
        ),
        title: Text(
          report.categoryName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          report.address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
        ),
        onTap: onPressed,
      ),
    );
  }
}

class _OperationLinks extends StatelessWidget {
  const _OperationLinks({required this.onOpenFleet, required this.onOpenStaff});

  final VoidCallback onOpenFleet;
  final VoidCallback onOpenStaff;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(14) > 18;
        final width = stack
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            SizedBox(
              width: width,
              child: _OperationLink(
                label: 'Flota',
                icon: Icons.local_shipping_outlined,
                onPressed: onOpenFleet,
              ),
            ),
            SizedBox(
              width: width,
              child: _OperationLink(
                label: 'Personal',
                icon: Icons.badge_outlined,
                onPressed: onOpenStaff,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OperationLink extends StatelessWidget {
  const _OperationLink({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _PanelSurface(
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minLeadingWidth: 22,
        horizontalTitleGap: 8,
        leading: Icon(icon, color: AppColors.forest, size: 21),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        trailing: const Icon(
          Icons.arrow_outward_rounded,
          size: 17,
          color: AppColors.textSecondary,
        ),
        onTap: onPressed,
      ),
    );
  }
}

class _PanelSurface extends StatelessWidget {
  const _PanelSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _panelBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
