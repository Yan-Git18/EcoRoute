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
  Uint8List? _imageBytes;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    final viewModel = ref.read(staffHomeViewModelProvider.notifier);
    final result = fromCamera
        ? await viewModel.pickEvidenceImageFromCamera()
        : await viewModel.pickEvidenceImageFromGallery();

    if (result.hasImage) {
      setState(() {
        _imageBytes = result.bytes;
        _error = null;
      });
    } else if (result.errorMessage != null) {
      setState(() => _error = result.errorMessage);
    }
  }

  Future<void> _submit() async {
    if (_imageBytes == null || _imageBytes!.isEmpty) {
      setState(
        () => _error = 'Por favor tome o elija una fotografía para validar la limpieza.',
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
      imageBytes: _imageBytes!,
      notes: notes,
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

            // 3. Título de sección: Evidencia fotográfica *
            Row(
              children: const [
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
            const SizedBox(height: 3),
            const Text(
              'Agrega una foto para validar la limpieza.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),

            // 4. Tarjetas de captura o previsualización de la foto
            if (_imageBytes != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _imageBytes!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () => setState(() => _imageBytes = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Foto seleccionada',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  // Tarjeta 'Tomar foto'
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickImage(true),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF047857),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xFF047857),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Tomar foto',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Tarjeta 'Elegir de galería'
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickImage(false),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF047857),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.photo_library_rounded,
                                color: Color(0xFF047857),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Elegir de galería',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
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
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Describe brevemente el trabajo realizado...',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
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
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'La fotografía es obligatoria para continuar.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
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
