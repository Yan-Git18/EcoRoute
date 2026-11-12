import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/report_thumbnail.dart';
import '../../domain/entities/report_entity.dart';
import 'report_status_badge.dart';

/// Tarjeta especializada para la vista de "Reportes Cercanos" (Vista 10).
///
/// Principio DRY: Utiliza [ReportThumbnail] y [DateFormatter].
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

  @override
  Widget build(BuildContext context) {
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
                    ReportThumbnail(
                      imageUrl: report.imageUrls.isNotEmpty ? report.imageUrls.first : null,
                      width: 72,
                      height: 72,
                      borderRadius: 12,
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
                          DateFormatter.formatShortDate(report.createdAt),
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
