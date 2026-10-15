import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../../../core/constants/geo_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../viewmodels/create_report_state.dart';
import '../../viewmodels/create_report_viewmodel.dart';

/// Vista del Paso 3: Selección de Ubicación con Mapa Real Interactivo y PIN Ajustable.
///
/// Permite al ciudadano:
/// 1. Ver un mapa real y dinámico (OpenStreetMap).
/// 2. Utilizar su posición GPS como punto de referencia.
/// 3. Arrastrar o tocar en el mapa para ubicar con precisión el PIN de la incidencia (e.g. basura en la calle).
/// 4. Actualizar la dirección y coordenadas en tiempo real para el registro del reporte.
///
/// Ubicación: `lib/features/citizen/presentation/views/steps/step_3_location_view.dart`
/// Capa: Presentation (Views / Steps)
class Step3LocationView extends ConsumerStatefulWidget {
  const Step3LocationView({super.key});

  @override
  ConsumerState<Step3LocationView> createState() => _Step3LocationViewState();
}

class _Step3LocationViewState extends ConsumerState<Step3LocationView> {
  late final TextEditingController _addressController;
  late final TextEditingController _referenceController;
  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey();

  LatLng? _draggedPinPosition;
  bool _isDraggingPin = false;
  bool _isMapReady = false;

  bool get _isFlutterTest {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  @override
  void initState() {
    super.initState();
    final state = ref.read(createReportViewModelProvider);
    _addressController = TextEditingController(text: state.address);
    _referenceController = TextEditingController(text: state.reference);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  LatLng get _effectivePinPosition {
    if (_draggedPinPosition != null) {
      return _draggedPinPosition!;
    }
    final state = ref.read(createReportViewModelProvider);
    return LatLng(state.latitude, state.longitude);
  }

  void _safeMoveMap(LatLng target, double zoom) {
    if (!_isFlutterTest && _isMapReady) {
      try {
        _mapController.move(target, zoom);
      } catch (_) {}
    }
  }

  void _zoomIn() {
    if (!_isFlutterTest && _isMapReady) {
      final zoom = _mapController.camera.zoom;
      if (zoom < AppGeoConstants.maxZoom) {
        _mapController.move(_mapController.camera.center, zoom + 1.0);
      }
    }
  }

  void _zoomOut() {
    if (!_isFlutterTest && _isMapReady) {
      final zoom = _mapController.camera.zoom;
      if (zoom > AppGeoConstants.minZoom) {
        _mapController.move(_mapController.camera.center, zoom - 1.0);
      }
    }
  }

  String? _getDistanceToUser(CreateReportState state, LatLng pinPos) {
    if (state.userLatitude == null || state.userLongitude == null) return null;
    final dist = Geolocator.distanceBetween(
      state.userLatitude!,
      state.userLongitude!,
      pinPos.latitude,
      pinPos.longitude,
    );
    if (dist < 20) return null; // Misma ubicación que el usuario
    if (dist < 1000) {
      return '${dist.round()} m de tu ubicación actual';
    } else {
      return '${(dist / 1000).toStringAsFixed(1)} km de tu ubicación actual';
    }
  }

  Future<void> _handleSearchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) return;
    final viewModel = ref.read(createReportViewModelProvider.notifier);
    final found = await viewModel.searchAndSetAddress(query);
    if (found && mounted) {
      final updated = ref.read(createReportViewModelProvider);
      final newPos = LatLng(updated.latitude, updated.longitude);
      setState(() {
        _draggedPinPosition = null;
      });
      _safeMoveMap(newPos, 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReportViewModelProvider);
    final viewModel = ref.read(createReportViewModelProvider.notifier);

    // Sincronizar controlador de dirección si se actualiza por GPS o búsqueda
    if (_addressController.text != state.address && !state.isLocating && !_isDraggingPin) {
      _addressController.text = state.address;
    }

    final effectivePin = _effectivePinPosition;
    final distanceText = _getDistanceToUser(state, effectivePin);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titular de la pantalla
          const Text(
            'Selecciona la ubicación',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Confirma la dirección exacta donde se localiza el problema para guiar al personal.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Campo de búsqueda / edición de dirección con botón buscar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _addressController,
              onChanged: viewModel.setManualAddress,
              onSubmitted: (_) => _handleSearchAddress(),
              decoration: InputDecoration(
                hintText: 'Buscar o ingresar dirección...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: IconButton(
                  icon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 22,
                  ),
                  tooltip: 'Buscar en el mapa',
                  onPressed: _handleSearchAddress,
                ),
                suffixIcon: state.isLocating
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_addressController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _addressController.clear();
                                viewModel.setManualAddress('');
                              },
                            ),
                        ],
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Contenedor visual del mapa real interactivo con PIN ajustable
          Container(
            key: _mapKey,
            height: 290,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Capa del mapa: FlutterMap real con OpenStreetMap o fallback vectorial en tests
                  Positioned.fill(
                    child: _isFlutterTest
                        ? _buildTestMap(state, viewModel)
                        : _buildOpenStreetMap(state, viewModel),
                  ),

                  // Chip superior con delimitación de cobertura Cajamarca
                  Positioned(
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withAlpha(210),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.location_city_rounded, color: Color(0xFF34D399), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Cajamarca • Toca o arrastra el PIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Controles de zoom vertical (+ / -) en la esquina superior derecha
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      children: [
                        _MapControlButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Acercar mapa',
                          onPressed: _zoomIn,
                        ),
                        const SizedBox(height: 6),
                        _MapControlButton(
                          icon: Icons.remove_rounded,
                          tooltip: 'Alejar mapa',
                          onPressed: _zoomOut,
                        ),
                      ],
                    ),
                  ),

                  // Botón flotante para recentrar en el PIN del incidente
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Column(
                      children: [
                        _MapControlButton(
                          icon: Icons.pin_drop_rounded,
                          iconColor: const Color(0xFFEF4444),
                          tooltip: 'Recentrar en el PIN',
                          onPressed: () {
                            _safeMoveMap(LatLng(state.latitude, state.longitude), 16.0);
                          },
                        ),
                        if (state.hasUserLocation) ...[
                          const SizedBox(height: 6),
                          _MapControlButton(
                            icon: Icons.my_location_rounded,
                            iconColor: AppColors.primary,
                            tooltip: 'Ver mi ubicación actual',
                            onPressed: () {
                              _safeMoveMap(
                                LatLng(state.userLatitude!, state.userLongitude!),
                                16.0,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Coordenadas flotantes en la esquina inferior izquierda
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(235),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          Text(
                            'Lat: ${effectivePin.latitude.toStringAsFixed(4)}  Long: ${effectivePin.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Advertencia si la ubicación está fuera del área urbana de Cajamarca
          if (!state.isLocationInsideCajamarca) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ubicación fuera del área de servicio. EcoRoute actualmente solo opera en Cajamarca.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Indicador de distancia relativa si el PIN difiere de la ubicación actual
          if (distanceText != null && state.isLocationInsideCajamarca) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.straighten_rounded, size: 15, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(
                    'Punto seleccionado a $distanceText',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Botón: Usar mi ubicación actual
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: state.isLocating
                  ? null
                  : () async {
                      await viewModel.getCurrentLocation();
                      if (mounted) {
                        final updated = ref.read(createReportViewModelProvider);
                        final newPos = LatLng(updated.latitude, updated.longitude);
                        setState(() {
                          _draggedPinPosition = null;
                        });
                        _safeMoveMap(newPos, 16.0);
                      }
                    },
              icon: const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 20),
              label: Text(
                state.isLocating ? 'Detectando GPS...' : 'Usar mi ubicación actual',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                backgroundColor: AppColors.primary.withAlpha(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Campo de Referencia Adicional
          const Text(
            'Referencia adicional (opcional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _referenceController,
              onChanged: viewModel.setReference,
              decoration: const InputDecoration(
                hintText: 'Ej. Al frente del parque, junto al poste de luz',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                prefixIcon: Icon(Icons.apartment_rounded, color: Color(0xFF64748B), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Vista de Mapa Real interactivo con FlutterMap y OpenStreetMap ---

  Widget _buildOpenStreetMap(CreateReportState state, CreateReportViewModel viewModel) {
    final markers = <Marker>[];

    // 1. Marcador de Referencia: Ubicación física actual del usuario (Punto azul pulsante)
    if (state.userLatitude != null && state.userLongitude != null) {
      markers.add(
        Marker(
          point: LatLng(state.userLatitude!, state.userLongitude!),
          width: 90,
          height: 68,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                child: const Text(
                  'Mi ubicación',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const _UserPulseMarker(),
            ],
          ),
        ),
      );
    }

    // 2. Marcador del PIN del incidente (Arrastrable e interactivo)
    markers.add(_buildDraggablePinMarker(state, viewModel));

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(state.latitude, state.longitude),
        initialZoom: AppGeoConstants.defaultZoom,
        minZoom: AppGeoConstants.minZoom,
        maxZoom: AppGeoConstants.maxZoom,
        cameraConstraint: AppGeoConstants.cameraConstraint,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        onMapReady: () {
          setState(() {
            _isMapReady = true;
          });
        },
        onTap: (_, point) {
          setState(() {
            _draggedPinPosition = null;
          });
          viewModel.updateCoordinates(point.latitude, point.longitude);
        },
      ),
      children: [
        // Capa de mosaicos OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ecoroute',
          maxZoom: 19,
        ),

        // Capa de Marcadores (GPS usuario + PIN del incidente)
        MarkerLayer(markers: markers),
      ],
    );
  }

  // --- Marcador del PIN con soporte de arrastre manual ---

  Marker _buildDraggablePinMarker(CreateReportState state, CreateReportViewModel viewModel) {
    final pinPosition = _effectivePinPosition;

    return Marker(
      point: pinPosition,
      width: 140,
      height: 75,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          setState(() {
            _isDraggingPin = true;
            _draggedPinPosition = pinPosition;
          });
        },
        onPanUpdate: (details) {
          final renderBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localOffset = renderBox.globalToLocal(details.globalPosition);
            // Ajustar posición al extremo inferior del pin
            final newLatLng = _mapController.camera.offsetToCrs(localOffset);
            setState(() {
              _draggedPinPosition = newLatLng;
            });
          }
        },
        onPanEnd: (details) {
          final finalPos = _draggedPinPosition;
          setState(() {
            _isDraggingPin = false;
          });
          if (finalPos != null) {
            viewModel.updateCoordinates(finalPos.latitude, finalPos.longitude);
          }
        },
        onPanCancel: () {
          setState(() {
            _isDraggingPin = false;
            _draggedPinPosition = null;
          });
        },
        child: AnimatedScale(
          scale: _isDraggingPin ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Etiqueta flotante del pin
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: _isDraggingPin ? AppColors.primaryDark : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(_isDraggingPin ? 80 : 50),
                      blurRadius: _isDraggingPin ? 10 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _isDraggingPin ? 'Suelta en el punto' : 'Punto del incidente',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Icono Pin Rojo con relieve
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: const Color(0xFFEF4444),
                    size: _isDraggingPin ? 48 : 44,
                    shadows: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withAlpha(_isDraggingPin ? 160 : 100),
                        blurRadius: _isDraggingPin ? 14 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  Positioned(
                    top: _isDraggingPin ? 9 : 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
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

  // --- Vista simulada para entorno de pruebas automatizadas (flutter test) ---

  Widget _buildTestMap(CreateReportState state, CreateReportViewModel viewModel) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        viewModel.updateCoordinates(
          AppGeoConstants.cajamarcaCenterLat,
          AppGeoConstants.cajamarcaCenterLng,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapGridPainter(),
            ),
          ),
          Positioned(
            bottom: 60,
            right: 80,
            child: const _UserPulseMarker(),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Punto del incidente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFEF4444),
                size: 46,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Botón circular flotante para controles del mapa ---

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final VoidCallback onPressed;

  const _MapControlButton({
    required this.icon,
    this.iconColor = const Color(0xFF334155),
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(240),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(
              icon,
              size: 19,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Marcador GPS del usuario con efecto pulso ---

class _UserPulseMarker extends StatelessWidget {
  const _UserPulseMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2563EB).withAlpha(40),
            border: Border.all(
              color: const Color(0xFF2563EB).withAlpha(120),
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

/// CustomPainter para el mapa vectorial en modo de prueba automatizada
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFEBF4EC);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final blockPaint = Paint()..color = const Color(0xFFDFEADB);
    final blockRects = [
      Rect.fromLTWH(15, 15, 60, 45),
      Rect.fromLTWH(90, 15, 100, 45),
      Rect.fromLTWH(205, 15, 80, 45),
      Rect.fromLTWH(15, 75, 60, 75),
      Rect.fromLTWH(90, 75, 100, 75),
      Rect.fromLTWH(205, 75, 80, 75),
      Rect.fromLTWH(15, 165, 60, 60),
      Rect.fromLTWH(90, 165, 100, 60),
      Rect.fromLTWH(205, 165, 80, 60),
    ];
    for (final rect in blockRects) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), blockPaint);
    }

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, 65), Offset(size.width, 65), roadPaint);
    canvas.drawLine(Offset(0, 155), Offset(size.width, 155), roadPaint);
    canvas.drawLine(Offset(80, 0), Offset(80, size.height), roadPaint);
    canvas.drawLine(Offset(195, 0), Offset(195, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
