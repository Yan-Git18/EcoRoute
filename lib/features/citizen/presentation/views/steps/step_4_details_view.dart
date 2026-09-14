import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/report_entity.dart';
import '../../viewmodels/create_report_viewmodel.dart';

/// Vista del Paso 4: Completa la información (Descripción y Prioridad).
///
/// Ubicación: `lib/features/citizen/presentation/views/steps/step_4_details_view.dart`
/// Capa: Presentation (Views / Steps)
class Step4DetailsView extends ConsumerStatefulWidget {
  const Step4DetailsView({super.key});

  @override
  ConsumerState<Step4DetailsView> createState() => _Step4DetailsViewState();
}

class _Step4DetailsViewState extends ConsumerState<Step4DetailsView> {
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(createReportViewModelProvider);
    _descriptionController = TextEditingController(text: state.description);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReportViewModelProvider);
    final viewModel = ref.read(createReportViewModelProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titular de la pantalla
          const Text(
            'Completa la información',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Añade detalles sobre el incidente y califica el nivel de urgencia percibido.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Campo de Descripción
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.description.length >= 5
                    ? AppColors.primary
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 300,
              onChanged: viewModel.setDescription,
              decoration: const InputDecoration(
                hintText: 'Hay bolsas de basura acumuladas desde hace varios días...',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  height: 1.4,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Selector de Prioridad
          const Text(
            'Prioridad',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Prioridad Baja
              Expanded(
                child: _PriorityOptionCard(
                  title: 'Baja',
                  icon: Icons.eco_outlined,
                  activeColor: const Color(0xFF10B981),
                  bgColor: const Color(0xFFF0FDF4),
                  isSelected: state.priority == ReportPriority.low,
                  onTap: () => viewModel.setPriority(ReportPriority.low),
                ),
              ),
              const SizedBox(width: 10),

              // Prioridad Media
              Expanded(
                child: _PriorityOptionCard(
                  title: 'Media',
                  icon: Icons.wb_sunny_outlined,
                  activeColor: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFFFBEB),
                  isSelected: state.priority == ReportPriority.medium,
                  onTap: () => viewModel.setPriority(ReportPriority.medium),
                ),
              ),
              const SizedBox(width: 10),

              // Prioridad Alta
              Expanded(
                child: _PriorityOptionCard(
                  title: 'Alta',
                  icon: Icons.local_fire_department_outlined,
                  activeColor: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFEF2F2),
                  isSelected: state.priority == ReportPriority.high,
                  onTap: () => viewModel.setPriority(ReportPriority.high),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Resumen de Validación antes de enviar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Resumen del reporte',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFE2E8F0)),
                _SummaryRow(
                  label: 'Categoría:',
                  value: state.selectedCategory?.name ?? 'Sin seleccionar',
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Fotografía:',
                  value: state.imageBytes != null ? 'Adjunta (1 foto)' : 'Sin fotografía',
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Dirección:',
                  value: state.address,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color activeColor;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityOptionCard({
    required this.title,
    required this.icon,
    required this.activeColor,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? bgColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? activeColor : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: activeColor.withAlpha(30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: isSelected ? activeColor : const Color(0xFF64748B), size: 28),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    color: isSelected ? activeColor : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
