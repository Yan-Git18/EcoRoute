import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/staff_task_entity.dart';
import '../viewmodels/staff_home_viewmodel.dart';

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
        () => _error = 'Por favor tome o seleccione una fotografía del área limpia.',
      );
      return;
    }

    if (_notesController.text.trim().length < 3) {
      setState(
        () => _error = 'Ingrese una breve nota de la resolución (mínimo 3 caracteres).',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final viewModel = ref.read(staffHomeViewModelProvider.notifier);
    final success = await viewModel.completeTask(
      taskId: widget.task.id,
      imageBytes: _imageBytes!,
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Tarea completada con éxito! Evidencia registrada en el sistema.',
            ),
            backgroundColor: AppColors.success,
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
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF047857),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resolver Tarea de Limpieza',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.task.reportNumber,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Fotografía de Evidencia (Obligatorio)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (_imageBytes != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _imageBytes!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: () => setState(() => _imageBytes = null),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(true),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Tomar Foto'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(false),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Galería'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            const Text(
              'Notas de Limpieza',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ej. Área desinfectada y libre de bolsas acumuladas.',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A5835),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Finalizar y Validar Limpieza',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
