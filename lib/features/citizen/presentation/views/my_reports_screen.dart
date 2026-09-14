import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/my_reports_state.dart';
import '../viewmodels/my_reports_viewmodel.dart';
import '../widgets/citizen_bottom_nav_bar.dart';
import '../widgets/report_card.dart';

/// Pantalla principal de "Mis reportes" con filtros de estado y menú inferior global.
///
/// Ubicación: `lib/features/citizen/presentation/views/my_reports_screen.dart`
/// Capa: Presentation (Views)
class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  @override
  void initState() {
    super.initState();
    // Asegurar recarga fresca de reportes al ingresar a la pantalla
    Future.microtask(() {
      ref.read(myReportsViewModelProvider.notifier).loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myReportsViewModelProvider);
    final viewModel = ref.read(myReportsViewModelProvider.notifier);

    final filteredList = state.filteredReports;

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
        title: const Text(
          'Mis reportes',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Selector horizontal de filtros (Pills)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ReportFilter.values.map((filter) {
                  final isSelected = state.selectedFilter == filter;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => viewModel.setFilter(filter),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              filter.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Lista de Reportes o Estado Vacío
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : filteredList.isEmpty
                    ? _EmptyReportsView(
                        selectedFilter: state.selectedFilter,
                        onCreateReport: () =>
                            context.push(RouteNames.citizenCreateReport),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: viewModel.refresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final report = filteredList[index];
                            return ReportCard(
                              report: report,
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
      ),
      bottomNavigationBar: const CitizenBottomNavBar(currentIndex: 3),
    );
  }
}

/// Estado vacío amigable cuando el ciudadano no tiene reportes
class _EmptyReportsView extends StatelessWidget {
  final ReportFilter selectedFilter;
  final VoidCallback onCreateReport;

  const _EmptyReportsView({
    required this.selectedFilter,
    required this.onCreateReport,
  });

  @override
  Widget build(BuildContext context) {
    final isAll = selectedFilter == ReportFilter.all;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_late_outlined,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isAll
                  ? 'No tienes reportes aún'
                  : 'No hay reportes ${selectedFilter.label.toLowerCase()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAll
                  ? 'Cuando reportes una incidencia o acumulación de residuos en tu comunidad, podrás seguir su estado en tiempo real desde aquí.'
                  : 'Ninguno de tus reportes coincide actualmente con el filtro seleccionado.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            if (isAll) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onCreateReport,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Crear mi primer reporte',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
