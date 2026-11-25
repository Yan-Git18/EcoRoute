import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import 'admin_report_detail_screen.dart';
import '../viewmodels/admin_reports_state.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_back_button.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/admin_filter_carousel.dart';
import '../widgets/admin_load_notice.dart';
import '../widgets/admin_report_card.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref
        .read(adminReportsViewModelProvider)
        .searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportsViewModelProvider);
    final viewModel = ref.read(adminReportsViewModelProvider.notifier);
    final reports = state.filteredReports;
    final hasQuery = state.searchQuery.trim().isNotEmpty;
    final hasFilters =
        hasQuery || state.selectedFilter != AdminReportFilter.all;
    final textTheme = Theme.of(context).textTheme;

    void clearSearch() {
      _searchController.clear();
      viewModel.setSearchQuery('');
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: const AdminBackButton(),
        title: const Text('Gestión de Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar reportes',
            onPressed: state.isLoading ? null : viewModel.refresh,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 856),
            child: RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: viewModel.refresh,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: AdminLoadNotice(
                      state: state,
                      onRetry: viewModel.refresh,
                    ),
                  ),
                  if (state.hasLoadedReports) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: viewModel.setSearchQuery,
                              decoration: InputDecoration(
                                hintText: 'Buscar en reportes cargados',
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: state.searchQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Limpiar búsqueda',
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: clearSearch,
                                      ),
                                filled: true,
                                fillColor: AppColors.surface,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _ReportFilters(
                              state: state,
                              onSelected: viewModel.setFilter,
                            ),
                            const SizedBox(height: 10),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                hasFilters
                                    ? '${reports.length} de ${state.reports.length} reportes cargados'
                                    : '${reports.length} incidencias cargadas',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (reports.isEmpty)
                      SliverToBoxAdapter(
                        child: _EmptyAdminReportsView(
                          hasMore: state.nextCursor != null,
                          hasFilters: hasFilters,
                          onReset: () {
                            clearSearch();
                            viewModel.setFilter(AdminReportFilter.all);
                          },
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList.separated(
                          itemCount: reports.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final report = reports[index];
                            return AdminReportCard(
                              key: ValueKey(report.id),
                              report: report,
                              onViewDetail: () {
                                if (GoRouter.maybeOf(context) != null) {
                                  context.push(
                                    RouteNames.adminReportLocation(report.id),
                                    extra: report,
                                  );
                                } else {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute(
                                      builder: (_) => AdminReportDetailScreen(
                                        reportId: report.id,
                                        initialReport: report,
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    if (state.nextCursor != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            children: [
                              if (state.loadMoreFailed)
                                const Text(
                                  'No se pudo cargar la página siguiente.',
                                ),
                              TextButton.icon(
                                onPressed:
                                    state.isLoading || state.isLoadingMore
                                    ? null
                                    : viewModel.loadMoreReports,
                                icon: const Icon(Icons.expand_more_rounded),
                                label: Text(
                                  state.isLoadingMore
                                      ? 'Cargando reportes…'
                                      : 'Cargar más reportes',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 1),
    );
  }
}

class _ReportFilters extends StatelessWidget {
  const _ReportFilters({required this.state, required this.onSelected});

  final AdminReportsState state;
  final ValueChanged<AdminReportFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final totals = state.totals;
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    return AdminFilterCarousel(
      children: [
        for (final filter in AdminReportFilter.values)
          ChoiceChip(
            selected: state.selectedFilter == filter,
            onSelected: (selected) {
              if (selected) onSelected(filter);
            },
            showCheckmark: false,
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primarySoft,
            side: BorderSide(
              color: state.selectedFilter == filter
                  ? AppColors.primaryDark
                  : AppColors.border,
            ),
            labelStyle: labelStyle?.copyWith(
              color: state.selectedFilter == filter
                  ? AppColors.primaryDark
                  : AppColors.textSecondary,
              fontWeight: state.selectedFilter == filter
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
            label: Wrap(
              spacing: 6,
              children: [
                Text(filter.label),
                if (totals != null)
                  Text(switch (filter) {
                    AdminReportFilter.all => '${totals.total}',
                    AdminReportFilter.pending => '${totals.pending}',
                    AdminReportFilter.assigned => '${totals.assigned}',
                    AdminReportFilter.inProgress => '${totals.inProgress}',
                    AdminReportFilter.resolved => '${totals.resolved}',
                  }),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyAdminReportsView extends StatelessWidget {
  const _EmptyAdminReportsView({
    required this.hasMore,
    required this.hasFilters,
    required this.onReset,
  });

  final bool hasMore;
  final bool hasFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 28,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            hasMore
                ? 'Sin coincidencias entre los reportes cargados'
                : hasFilters
                ? 'No hay reportes que coincidan con los filtros'
                : 'No hay reportes cargados',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (hasFilters)
            TextButton(
              onPressed: onReset,
              child: const Text('Restablecer filtros'),
            ),
        ],
      ),
    );
  }
}
