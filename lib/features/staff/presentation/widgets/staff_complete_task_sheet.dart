import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/staff_task_entity.dart';
import '../viewmodels/staff_home_viewmodel.dart';

/// Modal interactivo para resolver tareas de limpieza y adjuntar evidencia fotográfica.
///
/// Diseño fiel al mockup de diseño:
/// - Cabecera con ícono de check, folio de incidencia y badge 'En atención'
/// - Sección de 'Evidencia fotográfica *' con dos tarjetas: 'Tomar foto' y 'Elegir de galería'
/// - Sección de 'Notas de limpieza' con campo multilínea y contador de caracteres (0/500)
/// - Botón principal 'Finalizar limpieza' con ícono de check
/// - Nota informativa al pie: 'La fotografía es obligatoria para continuar.'
///
/// Ubicación: `lib/features/staff/presentation/widgets/staff_complete_task_sheet.dart`
/// Capa: Presentation (Widgets Staff)
class StaffCompleteTaskSheet extends ConsumerStatefulWidget {
  final StaffTaskEntity task;

  const StaffCompleteTaskSheet({super.key, required this.task});

  static void show(BuildContext context, StaffTaskEntity task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StaffCompleteTaskSheet(task: task),
    );
  }

  @override
  ConsumerState<StaffCompleteTaskSheet> createState() => _StaffCompleteTaskSheetState();
}

class _StaffCompleteTaskSheetState extends ConsumerState<StaffCompleteTaskSheet> {
  final _notesController = TextEditingController();
  final List<Uint8List> _imageBytesList = [];
  final List<String> _localImagePaths = [];
  static const int _maxEvidencePhotos = 4;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_imageBytesList.length >= _maxEvidencePhotos) {
      setState(() => _error = 'Has alcanzado el límite máximo de $_maxEvidencePhotos fotos.');
      return;
    }

    final viewModel = ref.read(staffHomeViewModelProvider.notifier);
    final result = await viewModel.pickEvidenceImageFromCamera();

    if (result.hasImage) {
      setState(() {
        _imageBytesList.add(result.bytes!);
        if (result.file?.path != null) {
          _localImagePaths.add(result.file!.path);
        }
        _error = null;
      });
    } else if (result.errorMessage != null) {
      setState(() => _error = result.errorMessage);
    }
  }

  void _removePhotoAt(int index) {
    setState(() {
      _imageBytesList.removeAt(index);
      if (index < _localImagePaths.length) {
        _localImagePaths.removeAt(index);
      }
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_imageBytesList.isEmpty) {
      setState(
        () => _error = 'Por favor tome al menos una fotografía instantánea para validar la limpieza.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : 'Limpieza y recolección completada con éxito.';

    final viewModel = ref.read(staffHomeViewModelProvider.notifier);
    final success = await viewModel.completeTask(
      taskId: widget.task.id,
      imageBytes: _imageBytesList.first,
      multipleImageBytes: _imageBytesList,
      notes: notes,
      localImagePath: _localImagePaths.isNotEmpty ? _localImagePaths.first : null,
      localImagePaths: _localImagePaths,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Tarea completada con éxito! Evidencia registrada.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(
          () => _error = 'Error al registrar la finalización de la tarea.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Manija superior de arrastre
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
            const SizedBox(height: 18),

            // 2. Cabecera con ícono de check, título y badge de estado
            Row(
              children: [
                // Ícono en contenedor verde menta suave
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFF047857),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Título y folio de incidencia
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resolver tarea',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Incidencia ${widget.task.reportNumber}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge 'En atención'
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7).withAlpha(160),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.5,
                        height: 6.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'En atención',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Título de sección: Evidencia fotográfica * (Solo cámara, hasta 4 fotos)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      'Evidencia fotográfica',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '*',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _imageBytesList.isNotEmpty
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${_imageBytesList.length} / $_maxEvidencePhotos fotos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _imageBytesList.isNotEmpty
                          ? const Color(0xFF047857)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              'Toma fotos instantáneas en el lugar para validar la limpieza (hasta 4 fotos, solo cámara).',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),

            // 4. Tarjetas de captura o previsualización de las fotos (Solo cámara)
            if (_imageBytesList.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageBytesList.length + (_imageBytesList.length < _maxEvidencePhotos ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == _imageBytesList.length) {
                      return InkWell(
                        onTap: _takePhoto,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF047857),
                              width: 1.2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, color: Color(0xFF047857), size: 24),
                              SizedBox(height: 4),
                              Text(
                                'Tomar otra',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final bytes = _imageBytesList[index];
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            bytes,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _removePhotoAt(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(160),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ] else
              InkWell(
                onTap: _takePhoto,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF047857),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Color(0xFF047857),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tomar foto instantánea',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Solo foto al instante (antifraude)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // 5. Sección: Notas de limpieza
            const Text(
              'Notas de limpieza',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _notesController.text.trim().isNotEmpty
                      ? const Color(0xFF047857)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    maxLength: 500,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    onChanged: (text) => setState(() {}),
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Describe brevemente el trabajo realizado...',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_notesController.text.length}/500',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Mensaje de error si la validación falla
            if (_error != null) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // 6. Botón de acción: Finalizar limpieza
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A5835),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Finalizar limpieza',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // 7. Nota informativa al pie
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Fotografía instantánea obligatoria (antifraude). Hasta 4 fotos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
