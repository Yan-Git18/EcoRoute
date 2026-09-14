import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../viewmodels/create_report_viewmodel.dart';

/// Vista del Paso 3: Selección de Ubicación en Mapa y Dirección.
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

  @override
  void initState() {
    super.initState();
    final state = ref.read(createReportViewModelProvider);
    _addressController = TextEditingController(text: state.address);
    _referenceController = TextEditingController(text: state.reference);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReportViewModelProvider);
    final viewModel = ref.read(createReportViewModelProvider.notifier);

    // Sincronizar controlador de dirección si se actualiza por GPS
    if (_addressController.text != state.address && !state.isLocating) {
      _addressController.text = state.address;
    }

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
            'Confirma la dirección exacta donde se localiza el problema para guiar a la cuadrilla.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Campo de búsqueda / edición de dirección
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
              decoration: InputDecoration(
                hintText: 'Buscar o ingresar dirección...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                  size: 22,
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
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _addressController.clear();
                          viewModel.setManualAddress('');
                        },
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Contenedor visual del mapa con pin central
          Container(
            height: 240,
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
                  // Fondo simulado de mapa vectorial estilizado
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MapGridPainter(),
                    ),
                  ),

                  // Pulso de ubicación actual (círculo azul semi-translúcido)
                  Positioned(
                    bottom: 60,
                    right: 80,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withAlpha(40),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Marcador Pin Rojo central
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
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
                      Container(
                        width: 8,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(60),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),

                  // Coordenadas flotantes en la esquina inferior izquierda
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Lat: ${state.latitude.toStringAsFixed(4)}  Long: ${state.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
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
          const SizedBox(height: 14),

          // Botón: Usar mi ubicación actual
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: state.isLocating ? null : viewModel.getCurrentLocation,
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
}

/// CustomPainter para dibujar un mapa estilizado con calles y bloques urbanos
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fondo base del mapa (terreno verde claro urbano)
    final bgPaint = Paint()..color = const Color(0xFFEBF4EC);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Pintura para manzanas / edificios urbanos
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

    // Calles en color blanco
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    // Vías horizontales
    canvas.drawLine(Offset(0, 65), Offset(size.width, 65), roadPaint);
    canvas.drawLine(Offset(0, 155), Offset(size.width, 155), roadPaint);

    // Vías verticales
    canvas.drawLine(Offset(80, 0), Offset(80, size.height), roadPaint);
    canvas.drawLine(Offset(195, 0), Offset(195, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
