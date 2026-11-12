import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Miniatura reutilizable de fotografía de reporte con soporte para URLs web, archivos locales y Base64.
///
/// Principio DRY y SRP: Encapsula la lógica de carga, caché y placeholder visual.
/// Ubicación: `lib/core/widgets/report_thumbnail.dart`
/// Capa: Core (Widgets)
class ReportThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const ReportThumbnail({
    super.key,
    required this.imageUrl,
    this.width = 72,
    this.height = 72,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFF1F5F9),
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return const _ThumbnailPlaceholder();
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
      );
    }

    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
        );
      } catch (_) {
        return const _ThumbnailPlaceholder();
      }
    }

    try {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
        );
      }
    } catch (_) {}

    return const _ThumbnailPlaceholder();
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Color(0xFF94A3B8),
          size: 28,
        ),
      ),
    );
  }
}

