import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_entity.dart';

/// Componente de mapa urbano comunitario interactivo basado en OpenStreetMap (100% gratuito).
///
/// Utiliza [FlutterMap] con teselas libres de OpenStreetMap para plataformas móviles, web y escritorio,
/// eliminando cualquier dependencia de claves de pago o cuotas de Google Maps.
///
/// Ubicación: `lib/features/citizen/presentation/widgets/citizen_map_view.dart`
/// Capa: Presentation (Widgets)
class CitizenMapView extends StatefulWidget {
  final List<ReportEntity> reports;
  final ReportEntity? selectedReport;
  final double userLatitude;
  final double userLongitude;
  final ValueChanged<ReportEntity?> onSelectReport;
  final ValueChanged<MapController?>? onMapCreated;

  const CitizenMapView({
    super.key,
    required this.reports,
    required this.selectedReport,
    required this.userLatitude,
    required this.userLongitude,
    required this.onSelectReport,
    this.onMapCreated,
  });

  @override
  State<CitizenMapView> createState() => CitizenMapViewState();
}

class CitizenMapViewState extends State<CitizenMapView> {
  final MapController _mapController = MapController();
  final TransformationController _desktopTransformController =
      TransformationController();

  bool get _isFlutterTest {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  @override
  void dispose() {
    _mapController.dispose();
    _desktopTransformController.dispose();
    super.dispose();
  }

  /// Mueve suavemente la cámara del mapa a las coordenadas especificadas.
  void animateToLocation(double lat, double lng, {double zoom = 15.5}) {
    if (!_isFlutterTest) {
      _mapController.move(LatLng(lat, lng), zoom);
    } else {
      _desktopTransformController.value = Matrix4.identity();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFlutterTest) {
      return _buildTestVectorMapView();
    }

    return _buildOpenStreetMap();
  }

  /// Vista de Mapa Real interactivo con OpenStreetMap y flutter_map
  Widget _buildOpenStreetMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(widget.userLatitude, widget.userLongitude),
        initialZoom: 14.5,
        minZoom: 3.0,
        maxZoom: 19.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onTap: (_, __) => widget.onSelectReport(null),
        onMapReady: () {
          widget.onMapCreated?.call(_mapController);
        },
      ),
      children: [
        // 1. Capa de teselas de OpenStreetMap (Gratuita, sin API key)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ecoroute',
          maxZoom: 19,
        ),

        // 2. Capa de Marcadores: GPS del usuario e incidencias comunitarias
        MarkerLayer(
          markers: [
            // Marcador de ubicación actual del usuario
            Marker(
              point: LatLng(widget.userLatitude, widget.userLongitude),
              width: 52,
              height: 52,
              alignment: Alignment.center,
              child: const _UserPulseMarker(),
            ),

            // Marcadores de reportes ciudadanos
            for (final report in widget.reports)
              _buildReportMarker(report),
          ],
        ),
      ],
    );
  }

  Marker _buildReportMarker(ReportEntity report) {
    final isSelected = widget.selectedReport?.id == report.id;
    final pinColor = _getStatusColor(report.status);

    return Marker(
      point: LatLng(report.latitude, report.longitude),
      width: isSelected ? 84 : 48,
      height: isSelected ? 80 : 54,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelectReport(report),
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Etiqueta flotante del folio si está seleccionado
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    report.reportNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              // Pin estilizado con icono y sombra
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: isSelected ? 46 : 40,
                    color: pinColor,
                    shadows: [
                      BoxShadow(
                        color: pinColor.withAlpha(120),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  Positioned(
                    top: isSelected ? 8 : 7,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: pinColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return AppColors.statusPending;
      case ReportStatus.inProgress:
      case ReportStatus.assigned:
        return AppColors.statusInProgress;
      case ReportStatus.resolved:
        return AppColors.statusResolved;
      case ReportStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  // --- Visor Vectorial de Respaldo para Pruebas Automatizadas (flutter test) ---

  Widget _buildTestVectorMapView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final centerLat = widget.userLatitude;
        final centerLng = widget.userLongitude;
        const double scale = 14000.0;

        return GestureDetector(
          onTap: () => widget.onSelectReport(null),
          child: Container(
            color: const Color(0xFFF1F5F9),
            child: InteractiveViewer(
              transformationController: _desktopTransformController,
              boundaryMargin: const EdgeInsets.all(500),
              minScale: 0.6,
              maxScale: 3.0,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(width, height),
                    painter: _UrbanMapPainter(),
                  ),
                  Positioned(
                    left: width / 2 - 20,
                    top: height / 2 - 20,
                    child: const _UserPulseMarker(),
                  ),
                  for (final report in widget.reports) ...[
                    _buildVectorMarker(
                      report: report,
                      width: width,
                      height: height,
                      centerLat: centerLat,
                      centerLng: centerLng,
                      scale: scale,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVectorMarker({
    required ReportEntity report,
    required double width,
    required double height,
    required double centerLat,
    required double centerLng,
    required double scale,
  }) {
    final dx = (report.longitude - centerLng) * scale;
    final dy = -(report.latitude - centerLat) * scale * 1.1;
    final posX = (width / 2) + dx;
    final posY = (height / 2) + dy;
    final isSelected = widget.selectedReport?.id == report.id;
    final pinColor = _getStatusColor(report.status);

    return Positioned(
      left: posX - 22,
      top: posY - 44,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelectReport(report),
        child: AnimatedScale(
          scale: isSelected ? 1.25 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.reportNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Icon(
                Icons.location_on_rounded,
                size: 44,
                color: pinColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marcador animado/estilizado para la posición GPS del usuario.
class _UserPulseMarker extends StatelessWidget {
  const _UserPulseMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2563EB).withAlpha(45),
            border: Border.all(
              color: const Color(0xFF2563EB).withAlpha(130),
              width: 1.5,
            ),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2563EB),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dibujador personalizado del fondo de mapa para tests automatizados.
class _UrbanMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final greenPaint = Paint()
      ..color = const Color(0xFFDCFCE7).withAlpha(160)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.15, size.width * 0.28, size.height * 0.2),
        const Radius.circular(16),
      ),
      greenPaint,
    );

    final streetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    void drawRoad(Path path) {
      canvas.drawPath(path, borderPaint);
      canvas.drawPath(path, streetPaint);
    }

    for (double y = 80; y < size.height; y += 120) {
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(size.width, y);
      drawRoad(path);
    }

    for (double x = 70; x < size.width; x += 110) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x, size.height);
      drawRoad(path);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
