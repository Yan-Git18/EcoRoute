import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Visor interactivo y tarjeta de evidencia fotográfica de resolución de incidencias.
///
/// Principio DRY y SRP: Reutilizado en StaffEvidenceDetailSheet y ReportDetailScreen.
/// Soporta imágenes HTTP/HTTPS, Base64 (Data URI) y archivos locales en dispositivo,
/// con badge de verificación, control de zoom interactivo y visor a pantalla completa.
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
    final imageWidget = _buildRawImage();

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

  Widget _buildRawImage() {
    final url = imageUrl.trim();

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF047857)),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildErrorImagePlaceholder(),
      );
    } else if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildErrorImagePlaceholder(),
        );
      } catch (_) {
        return _buildErrorImagePlaceholder();
      }
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildErrorImagePlaceholder(),
        );
      }
      return _buildErrorImagePlaceholder();
    }
  }

  Widget _buildErrorImagePlaceholder() {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, size: 42, color: Color(0xFF94A3B8)),
            SizedBox(height: 8),
            Text(
              'No se pudo cargar la imagen de evidencia',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

