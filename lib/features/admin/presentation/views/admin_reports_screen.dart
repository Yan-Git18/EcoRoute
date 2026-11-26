import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/geo/cajamarca_urban_zones.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../citizen/domain/entities/report_entity.dart';
import '../../domain/entities/admin_report_page.dart';
import 'admin_report_detail_screen.dart';
import '../models/admin_map_report_status.dart';
import '../viewmodels/admin_reports_state.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_back_button.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/admin_filter_carousel.dart';
import '../widgets/admin_load_notice.dart';
import '../widgets/admin_report_card.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key, this.zone, this.openOnly});

  final CajamarcaZone? zone;
  final bool? openOnly;

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _scrollController = ScrollController();
  AdminReportFilter _zoneFilter = AdminReportFilter.all;
  int _zoneLimit = AdminReportPage.pageSize;
  bool _loadScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.zone == null) {
      _searchController.text = ref
          .read(adminReportsViewModelProvider)
          .searchQuery;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadScheduled || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions ||
        position.pixels <= 0 ||
        position.extentAfter > 320) {
      return;
    }
    _loadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScheduled = false;
      if (!mounted) return;
      final zone = widget.zone;
      if (zone != null) {
        _loadMoreInZone(zone);
      } else {
        final state = ref.read(adminReportsViewModelProvider);
        if (!state.loadMoreFailed) {
          unawaited(
            ref.read(adminReportsViewModelProvider.notifier).loadMoreReports(),
          );
        }
      }
    });
  }

  AdminReportsState _zoneState(
    CajamarcaZone zone,
    AsyncValue<Map<CajamarcaZone, List<ReportEntity>>> zoned,
  ) {
    final zoneReports = zoned.value?[zone] ?? const <ReportEntity>[];
    final reports = widget.openOnly == true
        ? zoneReports.where((report) => report.isOpenForOperations).toList()
        : zoneReports;
    return AdminReportsState(
      isLoading: zoned.isLoading,
      hasLoadedReports: zoned.hasValue,
      reportsLoadFailed: zoned.hasError,
      reports: reports,
      totals: zoned.hasValue ? _zoneTotals(reports) : null,
      selectedFilter: _zoneFilter,
      searchQuery: _searchController.text,
    );
  }

  void _loadMoreInZone(CajamarcaZone zone) {
    final state = _zoneState(zone, ref.read(urbanReportsProvider));
    if (!state.isLoading && state.filteredReports.length > _zoneLimit) {
      setState(() => _zoneLimit += AdminReportPage.pageSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final state = zone == null
        ? ref.watch(adminReportsViewModelProvider)
        : _zoneState(zone, ref.watch(urbanReportsProvider));
    final viewModel = zone == null
        ? ref.read(adminReportsViewModelProvider.notifier)
        : null;
    final matchingReports = state.filteredReports;
    final reports = zone == null
        ? matchingReports
        : matchingReports.take(_zoneLimit).toList();
    final hasMore = zone == null
        ? state.nextCursor != null
        : matchingReports.length > _zoneLimit;
    final hasQuery = state.searchQuery.trim().isNotEmpty;
    final hasFilters =
        hasQuery || state.selectedFilter != AdminReportFilter.all;
    final totals = state.totals;
    final total = switch (state.selectedFilter) {
      AdminReportFilter.all => totals?.total,
      AdminReportFilter.pending => totals?.pending,
      AdminReportFilter.assigned => totals?.assigned,
      AdminReportFilter.inProgress => totals?.inProgress,
      AdminReportFilter.resolved => totals?.resolved,
    };
    final textTheme = Theme.of(context).textTheme;

    Future<void> refresh() async {
      if (viewModel != null) return viewModel.refresh();
      try {
        ref.invalidate(urbanReportsProvider);
        await ref.read(urbanReportsProvider.future);
      } catch (_) {
        // El proveedor conserva el error para mostrar el aviso y el reintento.
      }
    }

    void setSearch(String query) {
      if (viewModel != null) {
        viewModel.setSearchQuery(query);
      } else {
        setState(() => _zoneLimit = AdminReportPage.pageSize);
      }
    }

    void clearSearch() {
      _searchController.clear();
      setSearch('');
    }

    void setFilter(AdminReportFilter filter) {
      if (viewModel != null) {
        viewModel.setFilter(filter);
      } else {
        setState(() {
          _zoneFilter = filter;
          _zoneLimit = AdminReportPage.pageSize;
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: AdminBackButton(
          fallbackRoute: zone == null
              ? RouteNames.adminDashboard
              : RouteNames.adminLiveMap,
        ),
        title: Text(
          zone == null ? 'Gestión de Reportes' : 'Reportes: ${zone.name}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar reportes',
            onPressed: state.isLoading ? null : refresh,
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
              onRefresh: refresh,
              child: CustomScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: AdminLoadNotice(state: state, onRetry: refresh),
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
                              onChanged: setSearch,
                              decoration: InputDecoration(
                                hintText: zone == null
                                    ? 'Buscar en reportes cargados'
                                    : 'Buscar en esta zona',
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
                              onSelected: setFilter,
                              openOnly: widget.openOnly,
                            ),
                            const SizedBox(height: 10),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                hasQuery
                                    ? '${reports.length} coincidencias en los reportes cargados'
                                    : hasMore && total != null && total > reports.length
                                    ? '${reports.length} de $total ${switch (state.selectedFilter) {
                                        AdminReportFilter.all => 'incidencias cargadas',
                                        AdminReportFilter.pending => 'pendientes cargados',
                                        _ => 'reportes con el filtro',
                                      }}'
                                    : '${reports.length} ${hasFilters ? 'reportes con el filtro' : 'incidencias cargadas'}',
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
                          hasMore: zone == null && hasMore,
                          hasFilters: hasFilters,
                          onReset: () {
                            clearSearch();
                            setFilter(AdminReportFilter.all);
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
                    if (hasMore)
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
                                    : zone == null
                                    ? viewModel?.loadMoreReports
                                    : () => _loadMoreInZone(zone),
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

AdminReportTotals _zoneTotals(List<ReportEntity> reports) {
  final counts = <ReportStatus, int>{};
  for (final report in reports) {
    counts.update(report.status, (count) => count + 1, ifAbsent: () => 1);
  }
  return (
    total: reports.length,
    pending: counts[ReportStatus.pending] ?? 0,
    assigned: counts[ReportStatus.assigned] ?? 0,
    inProgress: counts[ReportStatus.inProgress] ?? 0,
    resolved: counts[ReportStatus.resolved] ?? 0,
  );
}

class _ReportFilters extends StatelessWidget {
  const _ReportFilters({
    required this.state,
    required this.onSelected,
    this.openOnly,
  });

  final AdminReportsState state;
  final ValueChanged<AdminReportFilter> onSelected;
  final bool? openOnly;

  @override
  Widget build(BuildContext context) {
    final totals = state.totals;
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    return AdminFilterCarousel(
      children: [
        for (final filter in AdminReportFilter.values)
          if (openOnly != true || filter != AdminReportFilter.resolved)
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
