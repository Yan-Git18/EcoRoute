import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_entity.dart';
import 'report_status_badge.dart';

/// Tarjeta especializada para la vista de "Reportes Cercanos" (Vista 10).
///
/// Destaca badges visuales de distancia estimada, nivel de prioridad y estado de atención.
///
/// Ubicación: `lib/features/citizen/presentation/widgets/nearby_report_card.dart`
/// Capa: Presentation (Widgets)
class NearbyReportCard extends StatelessWidget {
  final ReportEntity report;
  final String formattedDistance;
  final VoidCallback onTap;

  const NearbyReportCard({
    super.key,
    required this.report,
    required this.formattedDistance,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    const months = [
      'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
      'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'
    ];
    final monthName = months[date.month - 1];
    return '${date.day} $monthName ${date.year}';
  }

  Widget _buildThumbnail(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
        );
      }
      return const _ThumbnailPlaceholder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = report.imageUrls.isNotEmpty;
    final priority = report.priority;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila Superior: Número de reporte, badge de distancia y badge de estado
                Row(
                  children: [
                    // Badge de distancia destacada
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 13,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDistance,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Número de reporte
                    Text(
                      report.reportNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),

                    // Badge de estado
                    ReportStatusBadge(status: report.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Contenido central: Fotografía / Placeholder e información
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: const Color(0xFFF1F5F9),
                        child: hasImage
                            ? _buildThumbnail(report.imageUrls.first)
                            : const _ThumbnailPlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Datos textuales
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  report.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF475569),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Fila Inferior: Badge de prioridad y fecha
                Row(
                  children: [
                    // Badge de Prioridad
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: priority.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(priority.icon, size: 13, color: priority.color),
                          const SizedBox(width: 4),
                          Text(
                            'Prioridad ${priority.displayLabel}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: priority.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Fecha de creación
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(report.createdAt),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.primary,
          size: 24,
        ),
      ),
    );
  }
}
