import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../viewmodels/citizen_map_state.dart';
import '../viewmodels/citizen_map_viewmodel.dart';
import '../widgets/citizen_bottom_nav_bar.dart';
import '../widgets/citizen_map_legend.dart';
import '../widgets/citizen_map_preview_card.dart';
import '../widgets/citizen_map_search_bar.dart';
import '../widgets/citizen_map_view.dart';

/// Mapa interactivo de reportes comunitarios y del ciudadano.
class CitizenMapScreen extends ConsumerStatefulWidget {
  const CitizenMapScreen({super.key});

  @override
  ConsumerState<CitizenMapScreen> createState() => _CitizenMapScreenState();
}

class _CitizenMapScreenState extends ConsumerState<CitizenMapScreen> {
  final GlobalKey<CitizenMapViewState> _mapKey =
      GlobalKey<CitizenMapViewState>();
  bool _showOwnReports = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(citizenMapViewModelProvider.notifier).loadReports();
    });
  }

  void _recenterMap() {
    ref.read(citizenMapViewModelProvider.notifier).requestUserLocation().then((
      _,
    ) {
      if (!mounted) return;
      final updatedState = ref.read(citizenMapViewModelProvider);
      _mapKey.currentState?.animateToLocation(
        updatedState.userLatitude,
        updatedState.userLongitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(citizenMapViewModelProvider);
    final viewModel = ref.read(citizenMapViewModelProvider.notifier);
    final citizenId = _showOwnReports
        ? ref.watch(authViewModelProvider.select((auth) => auth.user?.id))
        : null;
    final ownReportsProvider = citizenId != null && citizenId.isNotEmpty
        ? citizenMapOwnReportsProvider(citizenId)
        : null;
    final ownReports = ownReportsProvider == null
        ? null
        : ref.watch(ownReportsProvider);
    final reports = _showOwnReports
        ? ownReports?.value?.dataOrNull ?? const <ReportEntity>[]
        : state.allReports;
    final isLoading = _showOwnReports
        ? ownReports?.isLoading ?? false
        : state.isLoading;
    final hasError = _showOwnReports
        ? ownReports?.hasError == true || ownReports?.value?.isFailure == true
        : state.errorMessage != null;

    void refresh() {
      if (_showOwnReports) {
        if (ownReportsProvider != null) ref.invalidate(ownReportsProvider);
      } else {
        viewModel.refresh();
      }
    }

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
              context.go(RouteNames.citizenHome);
            }
          },
        ),
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: _ViewModeToggle(
            showOwnReports: _showOwnReports,
            onToggle: (showOwnReports) {
              if (showOwnReports == _showOwnReports) return;
              viewModel.selectReport(null);
              setState(() => _showOwnReports = showOwnReports);
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Actualizar reportes',
            onPressed:
                isLoading || (_showOwnReports && ownReportsProvider == null)
                ? null
                : refresh,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (!_showOwnReports)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'Últimos ${ReportRepository.communityReportWindowDays} días · Hasta ${ReportRepository.communityReportLimit} reportes recientes',
                textAlign: TextAlign.center,
              ),
            ),
          if (hasError && !isLoading)
            TextButton(
              onPressed: refresh,
              child: const Text('No se pudo actualizar el mapa. Reintentar'),
            ),
          Expanded(
            child: _buildInteractiveMapView(
              state,
              viewModel,
              reports: reports,
              isLoading: isLoading,
              hasError: hasError,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CitizenBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildInteractiveMapView(
    CitizenMapState state,
    CitizenMapViewModel viewModel, {
    required List<ReportEntity> reports,
    required bool isLoading,
    required bool hasError,
  }) {
    final filteredReports = state.filterReports(reports);
    final selectedReport = filteredReports
        .where((report) => report.id == state.selectedReport?.id)
        .firstOrNull;

    return Stack(
      children: [
        Positioned.fill(
          child: CitizenMapView(
            key: _mapKey,
            reports: filteredReports,
            selectedReport: selectedReport,
            userLatitude: state.userLatitude,
            userLongitude: state.userLongitude,
            onSelectReport: viewModel.selectReport,
          ),
        ),

        // 2. Buscador y filtros de estado flotantes superiores
        Positioned(
          top: 14,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: CitizenMapSearchBar(
              currentQuery: state.searchQuery,
              selectedFilter: state.selectedFilter,
              onQueryChanged: viewModel.setSearchQuery,
              onFilterChanged: viewModel.setFilter,
            ),
          ),
        ),

        // 3. Leyenda flotante de estados (esquina superior derecha, bajo el buscador)
        const Positioned(
          top: 120,
          right: 16,
          child: SafeArea(bottom: false, child: CitizenMapLegend()),
        ),

        // 4. Banner informativo cuando aún no hay reportes en el área o para el filtro actual
        if (!isLoading && !hasError && filteredReports.isEmpty)
          Positioned(
            bottom: 24,
            left: 20,
            right: 76,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(245),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      reports.isNotEmpty
                          ? 'Sin incidencias para el filtro seleccionado.'
                          : _showOwnReports
                          ? 'Aún no tienes reportes.'
                          : 'No hay incidencias en este período.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (reports.isEmpty)
                    TextButton(
                      onPressed: () =>
                          context.push(RouteNames.citizenCreateReport),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Reportar',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

        Positioned(
          bottom: selectedReport == null ? 20 : 8,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _FloatingGpsButton(
                  isLocating: state.isLocating,
                  onPressed: _recenterMap,
                ),
              ),
              if (selectedReport != null)
                CitizenMapPreviewCard(
                  report: selectedReport,
                  formattedDistance: state.formattedDistanceToReport(
                    selectedReport,
                  ),
                  onClose: () => viewModel.selectReport(null),
                ),
            ],
          ),
        ),
        if (isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              color: AppColors.primary,
              semanticsLabel: 'Cargando reportes',
            ),
          ),
      ],
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  final bool showOwnReports;
  final ValueChanged<bool> onToggle;

  const _ViewModeToggle({required this.showOwnReports, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: 'Todos',
            icon: Icons.map_rounded,
            isSelected: !showOwnReports,
            onTap: () => onToggle(false),
          ),
          const SizedBox(width: 2),
          _ToggleButton(
            label: 'Mis reportes',
            icon: Icons.assignment_ind_rounded,
            isSelected: showOwnReports,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Botón de Geolocalización GPS ---

class _FloatingGpsButton extends StatelessWidget {
  final bool isLocating;
  final VoidCallback onPressed;

  const _FloatingGpsButton({required this.isLocating, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: isLocating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    size: 24,
                    color: AppColors.primary,
                  ),
          ),
        ),
      ),
    );
  }
}
