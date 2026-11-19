import 'package:flutter/material.dart';
import '../../../../core/widgets/eco_priority_indicator.dart';
import '../../../../core/widgets/report_thumbnail.dart';
import '../../domain/entities/staff_task_entity.dart';

/// Modal bottom sheet para que el Personal de Limpieza consulte el detalle integral
/// del reporte ciudadano antes de iniciar o resolver la tarea operativa.
///
/// Principio SRP: Presenta la descripción del ciudadano, carrusel de fotografías,
/// ubicación, referencia y permite iniciar o resolver directamente.
///
/// Ubicación: `lib/features/staff/presentation/widgets/staff_task_detail_sheet.dart`
/// Capa: Presentation (Widgets Staff)
class StaffTaskDetailSheet extends StatefulWidget {
  final StaffTaskEntity task;
  final VoidCallback onStart;
  final VoidCallback onResolve;

  const StaffTaskDetailSheet({
    super.key,
    required this.task,
    required this.onStart,
    required this.onResolve,
  });

  static void show({
    required BuildContext context,
    required StaffTaskEntity task,
    required VoidCallback onStart,
    required VoidCallback onResolve,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StaffTaskDetailSheet(
        task: task,
        onStart: onStart,
        onResolve: onResolve,
      ),
    );
  }

  @override
  State<StaffTaskDetailSheet> createState() => _StaffTaskDetailSheetState();
}

class _StaffTaskDetailSheetState extends State<StaffTaskDetailSheet> {
  int _activeCitizenPhotoIndex = 0;
  int _activeResolutionPhotoIndex = 0;

  void _openFullScreen(BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StaffFullScreenCarouselViewer(
          title: widget.task.reportNumber,
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final citizenPhotos = task.reportImageUrls.where((url) => url.trim().isNotEmpty).toList();
    final resolutionPhotos = task.evidenceImageUrls.isNotEmpty
        ? task.evidenceImageUrls
        : (task.evidenceImageUrl != null && task.evidenceImageUrl!.isNotEmpty
            ? [task.evidenceImageUrl!]
            : <String>[]);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Manija superior
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contenido desplazable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Encabezado con ícono, categoría y estado
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.cleaning_services_rounded,
                            color: Color(0xFF047857),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.categoryName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Incidencia ${task.reportNumber}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusPill(task),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Ubicación y Prioridad
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                task.address,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            EcoPriorityIndicator(priority: task.priority),
                          ],
                        ),
                        if (task.reference != null && task.reference!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.near_me_outlined, size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Ref: ${task.reference!}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Fotografías del reporte ciudadano (Carrusel)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Fotos del ciudadano',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (citizenPhotos.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_activeCitizenPhotoIndex + 1} de ${citizenPhotos.length} fotos',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (citizenPhotos.isNotEmpty)
                    _buildImageCarousel(
                      photos: citizenPhotos,
                      currentIndex: _activeCitizenPhotoIndex,
                      onPageChanged: (idx) => setState(() => _activeCitizenPhotoIndex = idx),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 30),
                          SizedBox(height: 6),
                          Text(
                            'El reporte no tiene fotos registradas',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 5. Descripción del problema ciudadano
                  const Text(
                    'Descripción de la incidencia',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      task.description.trim().isNotEmpty
                          ? task.description.trim()
                          : 'Sin descripción detallada por el ciudadano.',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),

                  // 6. Si ya está resuelta, mostrar evidencia de limpieza
                  if (task.isResolved) ...[
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Evidencia de resolución (Limpieza)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (resolutionPhotos.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_activeResolutionPhotoIndex + 1} de ${resolutionPhotos.length} fotos',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (resolutionPhotos.isNotEmpty)
                      _buildImageCarousel(
                        photos: resolutionPhotos,
                        currentIndex: _activeResolutionPhotoIndex,
                        onPageChanged: (idx) => setState(() => _activeResolutionPhotoIndex = idx),
                        badgeLabel: 'Zona atendida',
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'No se adjuntaron fotografías de resolución.',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                        ),
                      ),
                    if (task.resolutionNotes != null && task.resolutionNotes!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(
                          task.resolutionNotes!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 7. Botones de acción al pie
          _buildBottomActionButtons(context, task),
        ],
      ),
    );
  }

  Widget _buildStatusPill(StaffTaskEntity task) {
    if (task.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Pendiente',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
        ),
      );
    } else if (task.isInProgress) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'En proceso',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Resuelta ✓',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
        ),
      );
    }
  }

  Widget _buildImageCarousel({
    required List<String> photos,
    required int currentIndex,
    required ValueChanged<int> onPageChanged,
    String? badgeLabel,
  }) {
    final safeIndex = currentIndex < photos.length ? currentIndex : 0;

    return Container(
      height: 205,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: photos.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openFullScreen(context, photos, index),
                  child: ReportThumbnail(
                    imageUrl: photos[index],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: 0,
                  ),
                );
              },
            ),
            if (badgeLabel != null)
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
            if (photos.length > 1) ...[
              // Contador inferior izquierdo (ej. 1 de 3 fotos)
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${safeIndex + 1} de ${photos.length} fotos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Indicador central de puntos (dots) del carrusel
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(120),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(photos.length, (idx) {
                        final isCurrent = idx == safeIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isCurrent ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isCurrent ? Colors.white : Colors.white.withAlpha(140),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
            Positioned(
              bottom: 10,
              right: 10,
              child: Material(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openFullScreen(context, photos, safeIndex),
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

  Widget _buildBottomActionButtons(BuildContext context, StaffTaskEntity task) {
    if (task.isPending) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            widget.onStart();
          },
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: const Text(
            'Iniciar tarea de limpieza',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97706), // Ámbar solicitado
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    } else if (task.isInProgress) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            widget.onResolve();
          },
          icon: const Icon(Icons.check_circle_rounded, size: 20),
          label: const Text(
            'Completar y resolver incidencia',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF047857),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Cerrar detalle', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
    }
  }
}

/// Visor de carrusel a pantalla completa con zoom para el personal de limpieza.
class _StaffFullScreenCarouselViewer extends StatefulWidget {
  final String title;
  final List<String> images;
  final int initialIndex;

  const _StaffFullScreenCarouselViewer({
    required this.title,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_StaffFullScreenCarouselViewer> createState() => _StaffFullScreenCarouselViewerState();
}

class _StaffFullScreenCarouselViewerState extends State<_StaffFullScreenCarouselViewer> {
  late final PageController _pageController;
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

  @override
  Widget build(BuildContext context) {
    final total = widget.images.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          total > 1 ? '${widget.title} (${_currentIndex + 1} / $total)' : widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: total,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: ReportThumbnail(
                    imageUrl: widget.images[index],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    borderRadius: 0,
                  ),
                ),
              );
            },
          ),
          if (total > 1)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(total, (idx) {
                      final isCurrent = idx == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isCurrent ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isCurrent ? Colors.white : Colors.white.withAlpha(120),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
