import 'package:flutter/material.dart';
import 'report_thumbnail.dart';

/// Visor interactivo y tarjeta de evidencia fotográfica de resolución de incidencias.
///
/// Principio DRY y SRP: Reutilizado en StaffEvidenceDetailSheet y ReportDetailScreen.
/// Delega la carga y renderizado de la imagen en [ReportThumbnail].
/// Ubicación: `lib/core/widgets/evidence_image_card.dart`
/// Capa: Core (Widgets)
class EvidenceImageCard extends StatelessWidget {
  final String imageUrl;
  final String? reportTitle;
  final String badgeLabel;
  final double height;
  final BorderRadius borderRadius;

  const EvidenceImageCard({
    super.key,
    required this.imageUrl,
    this.reportTitle,
    this.badgeLabel = 'Zona atendida',
    this.height = 210,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  void _openFullScreenViewer(BuildContext context, Widget imageWidget) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(reportTitle ?? 'Evidencia fotográfica'),
          ),
          body: Center(
            child: InteractiveViewer(
              maxScale: 4.0,
              child: imageWidget,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = ReportThumbnail(
      imageUrl: imageUrl,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      borderRadius: 0,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: borderRadius,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            imageWidget,
            // 1. Badge flotante de estado atendido
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF047857).withAlpha(225),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Botón flotante para ampliar a pantalla completa
            Positioned(
              bottom: 10,
              right: 10,
              child: Material(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openFullScreenViewer(context, imageWidget),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Ampliar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
