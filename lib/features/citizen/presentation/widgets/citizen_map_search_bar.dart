import 'package:flutter/material.dart';
import '../../../../core/enums/report_filter.dart';
import '../../../../core/theme/app_colors.dart';

/// Barra de búsqueda flotante con chips de filtro de estado para el mapa y lista de cercanos.
///
/// Principio SRP: Responsabilidad única de capturar texto de búsqueda y selección de filtro de estado.
///
/// Ubicación: `lib/features/citizen/presentation/widgets/citizen_map_search_bar.dart`
/// Capa: Presentation (Widgets)
class CitizenMapSearchBar extends StatefulWidget {
  final String currentQuery;
  final ReportFilter selectedFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<ReportFilter> onFilterChanged;

  const CitizenMapSearchBar({
    super.key,
    required this.currentQuery,
    required this.selectedFilter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  @override
  State<CitizenMapSearchBar> createState() => _CitizenMapSearchBarState();
}

class _CitizenMapSearchBarState extends State<CitizenMapSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentQuery);
  }

  @override
  void didUpdateWidget(covariant CitizenMapSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentQuery != _controller.text && widget.currentQuery.isEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de búsqueda principal
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            onChanged: widget.onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por dirección o tipo de residuo...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                      onPressed: () {
                        _controller.clear();
                        widget.onQueryChanged('');
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Chips horizontales de estado
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ReportFilter.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = ReportFilter.values[index];
              final isSelected = widget.selectedFilter == filter;

              return InkWell(
                onTap: () => widget.onFilterChanged(filter),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white.withAlpha(240),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                      width: 1.1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (filter != ReportFilter.all) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : _getFilterColor(filter),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        filter.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getFilterColor(ReportFilter filter) {
    switch (filter) {
      case ReportFilter.pending:
        return AppColors.statusPending;
      case ReportFilter.inProgress:
        return AppColors.statusInProgress;
      case ReportFilter.resolved:
        return AppColors.statusResolved;
      case ReportFilter.all:
        return AppColors.primary;
    }
  }
}
