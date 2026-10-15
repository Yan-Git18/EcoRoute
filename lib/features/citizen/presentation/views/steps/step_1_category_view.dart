import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/report_category_entity.dart';
import '../../viewmodels/create_report_viewmodel.dart';

/// Vista del Paso 1: Selección de Categoría / Tipo de Problema.
///
/// Ubicación: `lib/features/citizen/presentation/views/steps/step_1_category_view.dart`
/// Capa: Presentation (Views / Steps)
class Step1CategoryView extends ConsumerWidget {
  const Step1CategoryView({super.key});

  IconData _getCategoryIcon(String iconKey) {
    switch (iconKey) {
      case 'delete_sweep_rounded':
        return Icons.delete_sweep_rounded;
      case 'cleaning_services_rounded':
        return Icons.cleaning_services_rounded;
      case 'recycling_rounded':
        return Icons.recycling_rounded;
      case 'restore_from_trash_rounded':
        return Icons.delete_forever_rounded;
      case 'warning_amber_rounded':
        return Icons.warning_amber_rounded;
      case 'delete_outline_rounded':
      default:
        return Icons.delete_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createReportViewModelProvider);
    final viewModel = ref.read(createReportViewModelProvider.notifier);

    final categories = state.categories.isNotEmpty
        ? state.categories
        : ReportCategoryEntity.defaultCategories;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titular de la pantalla
          const Text(
            '¿Qué problema encontraste?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecciona la categoría adecuada para que el personal municipal correcto sea asignado.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Lista de categorías
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = state.selectedCategory?.id == category.id;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.8 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.primary.withAlpha(25)
                          : const Color(0x08000000),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => viewModel.selectCategory(category),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          // Icono de la categoría
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withAlpha(30)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(category.icon),
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFF475569),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Título y descripción
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.forest
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                                if (category.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    category.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Indicador de selección / chevron
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.chevron_right_rounded,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF94A3B8),
                            size: isSelected ? 22 : 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
