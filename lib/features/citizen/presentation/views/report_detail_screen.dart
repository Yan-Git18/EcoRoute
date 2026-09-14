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

  String _formatDateTime(DateTime date) {
    const months = [
      'sep.', 'oct.', 'nov.', 'dic.', 'ene.', 'feb.',
      'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.'
    ];
    final monthName = months[(date.month + 3) % 12];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'p. m.' : 'a. m.';
    return '${date.day} $monthName ${date.year} - $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                  : _buildReportContent(_report!),
    );
  }

  Widget _buildReportContent(ReportEntity report) {
    final hasImage = report.imageUrls.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Fotografía panorámica de la incidencia
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: hasImage
                  ? Image.network(
                      report.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _NoPhotoHeader(),
                    )
                  : const _NoPhotoHeader(),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Número de reporte y Badge de estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                report.reportNumber,
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
          const SizedBox(height: 6),

          // 3. Categoría del reporte
          Text(
            report.categoryName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),

          // 4. Ubicación con pin verde
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  report.address,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (report.reference != null && report.reference!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: Text(
                'Ref: ${report.reference}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18.0),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
          ),

          // 5. Descripción
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            report.description,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),

          // 6. Fecha de reporte
          const Text(
            'Fecha de reporte',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDateTime(report.createdAt),
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // 7. Prioridad
          const Text(
            'Prioridad',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          _PriorityBadge(priority: report.priority),
          const SizedBox(height: 18),

          // 8. Estado
          const Text(
            'Estado',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          ReportStatusBadge(status: report.status, showIcon: true),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
          ),

          // 9. Historial de estados (Timeline)
          const Text(
            'Historial de estados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          ReportTimeline(report: report),
        ],
      ),
    );
  }
}

class _NoPhotoHeader extends StatelessWidget {
  const _NoPhotoHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_outlined, size: 40, color: Color(0xFF94A3B8)),
            SizedBox(height: 6),
            Text(
              'Sin fotografía adjunta',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final ReportPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (bg, text, icon) = switch (priority) {
      ReportPriority.low => (
          const Color(0xFFF0FDF4),
          const Color(0xFF16A34A),
          Icons.eco_rounded,
        ),
      ReportPriority.medium => (
          const Color(0xFFFFFBEB),
          const Color(0xFFD97706),
          Icons.wb_sunny_rounded,
        ),
      ReportPriority.high => (
          const Color(0xFFFEF2F2),
          const Color(0xFFDC2626),
          Icons.local_fire_department_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: text.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: text),
          const SizedBox(width: 6),
          Text(
            priority.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
