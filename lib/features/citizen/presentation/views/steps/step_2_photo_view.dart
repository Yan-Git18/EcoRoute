import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../viewmodels/create_report_state.dart';
import '../../viewmodels/create_report_viewmodel.dart';

/// Vista del Paso 2: Evidencia Fotográfica con soporte para múltiples imágenes.
///
/// Ubicación: `lib/features/citizen/presentation/views/steps/step_2_photo_view.dart`
/// Capa: Presentation (Views / Steps)
class Step2PhotoView extends ConsumerStatefulWidget {
  const Step2PhotoView({super.key});

  @override
  ConsumerState<Step2PhotoView> createState() => _Step2PhotoViewState();
}

class _Step2PhotoViewState extends ConsumerState<Step2PhotoView> {
  int _activePhotoIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReportViewModelProvider);
    final viewModel = ref.read(createReportViewModelProvider.notifier);

    final hasImages = state.hasImage;
    final imagesCount = state.imagesCount;

    // Ajustar el índice activo si se eliminaron elementos
    if (_activePhotoIndex >= imagesCount && imagesCount > 0) {
      _activePhotoIndex = imagesCount - 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titular y contador de imágenes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Agrega una fotografía',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasImages
                      ? AppColors.primary.withAlpha(20)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasImages
                        ? AppColors.primary.withAlpha(70)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  '$imagesCount / ${CreateReportState.maxImages} fotos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: hasImages ? AppColors.primary : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Puedes adjuntar hasta 4 fotografías para mostrar diferentes ángulos del problema de residuos.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Área de visualización de fotografías
          if (hasImages) ...[
            // Visor principal con PageView
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: imagesCount,
                      onPageChanged: (index) {
                        setState(() {
                          _activePhotoIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Image.memory(
                          state.imageBytesList[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    ),

                    // Badge de número de foto actual (ej. 1/3)
                    if (imagesCount > 1)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(160),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Foto ${_activePhotoIndex + 1} de $imagesCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // Botón para eliminar foto actualmente visualizada
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Colors.black.withAlpha(160),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            viewModel.removeImageAt(_activePhotoIndex);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tira horizontal de miniaturas
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imagesCount + (state.canAddMoreImages ? 1 : 0),
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  // Botón '+' para agregar más fotos
                  if (index == imagesCount) {
                    return Material(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showAddPhotoSourceDialog(context, viewModel),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: AppColors.primary, size: 24),
                              SizedBox(height: 2),
                              Text(
                                'Añadir',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final isActive = index == _activePhotoIndex;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _activePhotoIndex = index;
                          });
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withAlpha(60),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.memory(
                              state.imageBytesList[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // Botón individual de borrado rápido
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => viewModel.removeImageAt(index),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
          ] else ...[
            // Estado vacío / Placeholder inicial
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ninguna foto adjunta aún',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Puedes capturar o seleccionar hasta 4 imágenes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Botones de acción para agregar fotos
          if (state.canAddMoreImages) ...[
            // Botón 1: Tomar Foto
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: viewModel.pickImageFromCamera,
                icon: const Icon(Icons.camera_alt_rounded, size: 20),
                label: Text(
                  hasImages ? 'Tomar otra foto' : 'Tomar foto',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botón 2: Elegir de la galería
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: viewModel.pickImageFromGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: Text(
                  hasImages ? 'Agregar más de la galería' : 'Elegir de la galería',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Límite alcanzado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Has adjuntado el número máximo de fotografías (4/4). Puedes eliminar alguna si deseas cambiarla.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Tarjeta de sugerencia / tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Recomendación: Asegúrate de encuadrar el tipo de residuo y elementos de referencia (fachadas, postes o esquinas).',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPhotoSourceDialog(BuildContext context, CreateReportViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Agregar fotografía',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Tomar foto con cámara'),
                onTap: () {
                  Navigator.pop(ctx);
                  viewModel.pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  viewModel.pickImageFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
