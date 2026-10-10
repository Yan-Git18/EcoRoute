import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/report_filter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/citizen_map_state.dart';
import '../viewmodels/citizen_map_viewmodel.dart';
import '../widgets/citizen_bottom_nav_bar.dart';
import '../widgets/citizen_map_legend.dart';
import '../widgets/citizen_map_preview_card.dart';
import '../widgets/citizen_map_search_bar.dart';
import '../widgets/citizen_map_view.dart';
import '../widgets/nearby_report_card.dart';

/// Pantalla unificada del Mapa Urbano y Reportes Cercanos (Vistas 9 y 10).
///
/// Permite alternar de manera fluida entre la vista de Mapa Interactivo con pines coloreados
/// (Vista 9) y el listado clasificado de Reportes Cercanos con badges de distancia/prioridad (Vista 10).
///
/// Ubicación: `lib/features/citizen/presentation/views/citizen_map_screen.dart`
/// Capa: Presentation (Views)
class CitizenMapScreen extends ConsumerStatefulWidget {
  const CitizenMapScreen({super.key});

  @override
  ConsumerState<CitizenMapScreen> createState() => _CitizenMapScreenState();
}

class _CitizenMapScreenState extends ConsumerState<CitizenMapScreen> {
  final GlobalKey<CitizenMapViewState> _mapKey = GlobalKey<CitizenMapViewState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(citizenMapViewModelProvider.notifier).loadReports();
    });
  }

  void _recenterMap(CitizenMapState state) {
    ref.read(citizenMapViewModelProvider.notifier).requestUserLocation().then((_) {
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
        title: _ViewModeToggle(
          isListView: state.isListView,
          onToggle: viewModel.toggleViewMode,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Actualizar reportes',
            onPressed: () => viewModel.refresh(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: state.isLoading
          ? const _MapLoadingView()
          : state.isListView
              ? _buildNearbyListView(state, viewModel)
              : _buildInteractiveMapView(state, viewModel),
      bottomNavigationBar: const CitizenBottomNavBar(currentIndex: 1),
    );
  }

  // --- Vista 9: Mapa Interactivo Completo ---

  Widget _buildInteractiveMapView(CitizenMapState state, CitizenMapViewModel viewModel) {
    return Stack(
      children: [
        // 1. Capa base: Mapa interactivo (Google Maps en mobile/web o visor vectorial en desktop)
        Positioned.fill(
          child: CitizenMapView(
            key: _mapKey,
            reports: state.filteredReports,
            selectedReport: state.selectedReport,
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
        Positioned(
          top: 120,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: const CitizenMapLegend(),
          ),
        ),

        // 4. Botón flotante de geolocalización / Recentrado en ubicación actual
        Positioned(
          bottom: state.selectedReport != null ? 220 : 20,
          right: 16,
          child: _FloatingGpsButton(
            isLocating: state.isLocating,
            onPressed: () => _recenterMap(state),
          ),
        ),

        // 5. Tarjeta flotante emergente de reporte seleccionado (al presionar un pin)
        if (state.selectedReport != null)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              offset: Offset.zero,
              curve: Curves.easeOutCubic,
              child: CitizenMapPreviewCard(
                report: state.selectedReport!,
                formattedDistance: state.formattedDistanceToReport(state.selectedReport!),
                onClose: () => viewModel.selectReport(null),
              ),
            ),
          ),
      ],
    );
  }

  // --- Vista 10: Reportes Cercanos (Modo Lista) ---

  Widget _buildNearbyListView(CitizenMapState state, CitizenMapViewModel viewModel) {
    final nearbyReports = state.nearbyReports;

    return Column(
      children: [
        // Barra de búsqueda y filtros
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: CitizenMapSearchBar(
            currentQuery: state.searchQuery,
            selectedFilter: state.selectedFilter,
            onQueryChanged: viewModel.setSearchQuery,
            onFilterChanged: viewModel.setFilter,
          ),
        ),

        // Franja de resumen de cercanía
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.radar_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${nearbyReports.length} incidencias ordenadas por proximidad',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => viewModel.requestUserLocation(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.gps_fixed_rounded, size: 13, color: AppColors.primaryDark),
                    SizedBox(width: 4),
                    Text(
                      'Mi GPS',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Listado de reportes cercanos
        Expanded(
          child: nearbyReports.isEmpty
              ? _EmptyNearbyReportsView(
                  filter: state.selectedFilter,
                  onClearFilters: () {
                    viewModel.setSearchQuery('');
                    viewModel.setFilter(ReportFilter.all);
                  },
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: viewModel.refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: nearbyReports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final report = nearbyReports[index];
                      final distance = state.formattedDistanceToReport(report);

                      return NearbyReportCard(
                        report: report,
                        formattedDistance: distance,
                        onTap: () {
                          context.push(
                            '/citizen/report/${report.id}',
                            extra: report,
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// --- Componente Selector de Modo de Vista (Mapa vs Lista) ---

class _ViewModeToggle extends StatelessWidget {
  final bool isListView;
  final ValueChanged<bool> onToggle;

  const _ViewModeToggle({
    required this.isListView,
    required this.onToggle,
  });

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
            label: 'Mapa',
            icon: Icons.map_rounded,
            isSelected: !isListView,
            onTap: () => onToggle(false),
          ),
          const SizedBox(width: 2),
          _ToggleButton(
            label: 'Cercanos',
            icon: Icons.format_list_bulleted_rounded,
            isSelected: isListView,
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
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
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

  const _FloatingGpsButton({
    required this.isLocating,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: const [
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

// --- Estado Vacío para la Vista de Cercanos ---

class _EmptyNearbyReportsView extends StatelessWidget {
  final ReportFilter filter;
  final VoidCallback onClearFilters;

  const _EmptyNearbyReportsView({
    required this.filter,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No se encontraron reportes cercanos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter == ReportFilter.all
                  ? 'No hay incidencias registradas en esta área geográfica o con los términos buscados.'
                  : 'No hay reportes ${filter.label.toLowerCase()} en tu zona inmediata.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Restablecer filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Vista de Carga ---

class _MapLoadingView extends StatelessWidget {
  const _MapLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Cargando incidencias comunitarias...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
