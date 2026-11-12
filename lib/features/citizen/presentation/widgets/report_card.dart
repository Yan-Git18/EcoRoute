import 'package:flutter/material.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/report_thumbnail.dart';
import '../../domain/entities/report_entity.dart';
import 'report_status_badge.dart';

/// Tarjeta para la visualización resumida de un reporte en la lista.
///
/// Principio DRY: Utiliza [ReportThumbnail] y [DateFormatter].
/// Ubicación: `lib/features/citizen/presentation/widgets/report_card.dart`
/// Capa: Presentation (Widgets)
class ReportCard extends StatelessWidget {
  final ReportEntity report;
  final VoidCallback onTap;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Miniatura de la fotografía o placeholder temático
                ReportThumbnail(
                  imageUrl: report.imageUrls.isNotEmpty ? report.imageUrls.first : null,
                  width: 72,
                  height: 72,
                  borderRadius: 12,
                ),
                const SizedBox(width: 14),

                // Información textual del reporte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.reportNumber,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        report.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        report.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormatter.formatShortDate(report.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Badge de estado
                ReportStatusBadge(status: report.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
