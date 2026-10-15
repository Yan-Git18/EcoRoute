import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_entity.dart';
import '../viewmodels/my_reports_viewmodel.dart';
import '../widgets/report_status_badge.dart';
import '../widgets/report_timeline.dart';

/// Pantalla de detalle y seguimiento integral de un reporte ciudadano.
///
/// Ubicación: `lib/features/citizen/presentation/views/report_detail_screen.dart`
/// Capa: Presentation (Views)
class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;
  final ReportEntity? initialReport;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    this.initialReport,
  });

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  ReportEntity? _report;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _report = widget.initialReport;
    if (_report == null) {
      _fetchReport();
    }
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final getReportById = ref.read(getReportByIdUseCaseProvider);
    final result = await getReportById(widget.reportId);

    if (mounted) {
      result.fold(
        onSuccess: (data) {
          setState(() {
            _report = data;
            _isLoading = false;
          });
        },
        onFailure: (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
        },
      );
    }
  }

  Future<void> _handleCancelReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 26),
            SizedBox(width: 10),
            Text('Cancelar reporte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de cancelar este reporte? Si el problema ya fue solucionado o fue reportado por error, puedes cancelarlo. Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Volver', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sí, cancelar reporte', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && _report != null) {
      setState(() => _isLoading = true);
      final cancelUseCase = ref.read(cancelReportUseCaseProvider);
      final result = await cancelUseCase(reportId: _report!.id);

      if (mounted) {
        result.fold(
          onSuccess: (updatedReport) {
            setState(() {
              _report = updatedReport;
              _isLoading = false;
            });
            // Recargar listado en segundo plano
            ref.read(myReportsViewModelProvider.notifier).loadReports();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('El reporte ha sido cancelado con éxito.'),
                  ],
                ),
                backgroundColor: const Color(0xFF475569),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          onFailure: (failure) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Detalle del reporte',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchReport,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _report == null
                  ? const SizedBox.shrink()
                  : _ReportDetailBody(
                      report: _report!,
                      onCancelReport: _handleCancelReport,
                    ),
    );
  }
}

/// Contenedor de las tarjetas de información del reporte.
/// Principio SRP: Distribuye cada sección en componentes especializados y reutilizables.
class _ReportDetailBody extends StatelessWidget {
  final ReportEntity report;
  final VoidCallback onCancelReport;

  const _ReportDetailBody({
    required this.report,
    required this.onCancelReport,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Fotografía de la incidencia / Placeholder punteado
          _ReportPhotoCard(imageUrls: report.imageUrls),
          const SizedBox(height: 16),

          // 2. Tarjeta resumen: Número de reporte, estado, categoría y dirección
          _ReportSummaryCard(report: report),
          const SizedBox(height: 16),

          // 3. Tarjeta de detalles: Descripción, fecha de reporte y métricas de prioridad/estado
          _ReportDetailsCard(report: report),
          const SizedBox(height: 16),

          // 4. Tarjeta historial de estados (Timeline de auditoría)
          _ReportTimelineCard(report: report),
          const SizedBox(height: 20),

          // 5. Botón de Cancelar Reporte para el ciudadano (solo en estado pendiente)
          if (report.status == ReportStatus.pending) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: onCancelReport,
                icon: const Icon(Icons.cancel_outlined, size: 20, color: Color(0xFFDC2626)),
                label: const Text(
                  'Cancelar reporte',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.3),
                  backgroundColor: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ] else if (report.status == ReportStatus.cancelled) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Este reporte fue cancelado y no requiere atención por parte del personal municipal.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta de imagen superior con bordes redondeados, soporte para URLs remotas y archivos locales,
/// carrusel interactivo para múltiples fotografías y visor a pantalla completa con zoom.
class _ReportPhotoCard extends StatefulWidget {
  final List<String> imageUrls;

  const _ReportPhotoCard({required this.imageUrls});

  @override
  State<_ReportPhotoCard> createState() => _ReportPhotoCardState();
}

class _ReportPhotoCardState extends State<_ReportPhotoCard> {
  int _currentIndex = 0;

  Widget _buildSingleImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const _EmptyPhotoPlaceholder(),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const _EmptyPhotoPlaceholder(),
        );
      }
      return const _EmptyPhotoPlaceholder();
    }
  }

  void _openFullScreenViewer(BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(
          imageUrls: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validImages = widget.imageUrls.where((url) => url.trim().isNotEmpty).toList();

    if (validImages.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          child: _EmptyPhotoPlaceholder(),
        ),
      );
    }

    if (validImages.length == 1) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C0F172A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildSingleImage(validImages.first),
              Positioned(
                bottom: 12,
                right: 12,
                child: Material(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openFullScreenViewer(context, validImages, 0),
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

    return Container(
      height: 215,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: validImages.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openFullScreenViewer(context, validImages, index),
                  child: _buildSingleImage(validImages[index]),
                );
              },
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_currentIndex + 1} de ${validImages.length} fotos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Material(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openFullScreenViewer(context, validImages, _currentIndex),
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

/// Visor a pantalla completa interactivo con soporte para pellizco para hacer zoom (Pinch-to-zoom).
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({required this.imageUrls, this.initialIndex = 0});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return InteractiveViewer(
        maxScale: 4.0,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
          ),
        ),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return InteractiveViewer(
          maxScale: 4.0,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
            ),
          ),
        );
      }
      return const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Foto ${_currentIndex + 1} de ${widget.imageUrls.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (ctx, i) => Center(child: _buildImage(widget.imageUrls[i])),
      ),
    );
  }
}

/// Componente para el estado sin imagen con marco redondeado punteado.
class _EmptyPhotoPlaceholder extends StatelessWidget {
  const _EmptyPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: CustomPaint(
        painter: const _DashedRRectPainter(
          color: Color(0xFFD3DDE7),
          strokeWidth: 1.2,
          radius: 14.0,
          dashWidth: 6.0,
          dashSpace: 4.0,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 46,
                color: Color(0xFF8DA4BE),
              ),
              SizedBox(height: 8),
              Text(
                'Sin fotografía adjunta',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8DA4BE),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pintor personalizado para dibujar un rectángulo con bordes redondeados punteados.
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  const _DashedRRectPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.radius = 14.0,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        dashPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      radius != oldDelegate.radius ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace;
}

/// Tarjeta de resumen de reporte: Número (#920049), Badge de estado, Categoría y Dirección con pin.
class _ReportSummaryCard extends StatelessWidget {
  final ReportEntity report;

  const _ReportSummaryCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final reportNum = report.reportNumber.startsWith('#')
        ? report.reportNumber
        : '#${report.reportNumber}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDF2F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                reportNum,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              ReportStatusBadge(
                status: report.status,
                showIcon: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.categoryName,
            style: const TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.address,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (report.reference != null &&
                        report.reference!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Ref: ${report.reference}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF94A3B8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de información detallada: Descripción, Fecha de reporte y Métricas de Prioridad / Estado.
class _ReportDetailsCard extends StatelessWidget {
  final ReportEntity report;

  const _ReportDetailsCard({required this.report});

  String _formatDateTime(DateTime date) {
    const months = [
      '',
      'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
      'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'
    ];
    final monthName = months[date.month];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'p. m.' : 'a. m.';
    return '${date.day} $monthName ${date.year} - $hour:$minute $period';
  }

  IconData _getPriorityIcon(ReportPriority priority) {
    switch (priority) {
      case ReportPriority.high:
        return Icons.local_fire_department_rounded;
      case ReportPriority.medium:
        return Icons.wb_sunny_rounded;
      case ReportPriority.low:
        return Icons.eco_rounded;
    }
  }

  Color _getPriorityColor(ReportPriority priority) {
    switch (priority) {
      case ReportPriority.high:
        return const Color(0xFFDC2626);
      case ReportPriority.medium:
        return const Color(0xFFD97706);
      case ReportPriority.low:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDF2F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Descripción con caja de icono
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF64748B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.description,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18.0),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 1.2, height: 1.2),
          ),

          // 2. Fecha de reporte con caja de icono
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha de reporte',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(report.createdAt),
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18.0),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 1.2, height: 1.2),
          ),

          // 3. Métricas divididas en dos columnas: Prioridad y Estado
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Columna 1: Prioridad
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        _getPriorityIcon(report.priority),
                        size: 26,
                        color: _getPriorityColor(report.priority),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Prioridad',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              report.priority.label,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _getPriorityColor(report.priority),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Divisor vertical
                Container(
                  width: 1.2,
                  height: 38,
                  color: const Color(0xFFF1F5F9),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),

                // Columna 2: Estado
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        report.status.icon,
                        size: 26,
                        color: report.status.color,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Estado',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              report.status.displayLabel,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: report.status.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta envolvente para la línea de tiempo de auditoría de estados.
class _ReportTimelineCard extends StatelessWidget {
  final ReportEntity report;

  const _ReportTimelineCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDF2F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de estados',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          ReportTimeline(report: report),
        ],
      ),
    );
  }
}
