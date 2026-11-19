import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/media_picker_service.dart';
import '../../../../core/widgets/auth/auth_text_field.dart';
import '../../../../core/widgets/eco_bottom_sheet.dart';
import '../../../../core/widgets/media_image.dart';
import '../../../../core/widgets/profile/profile_data_modal.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/repositories/firebase_citizen_profile_repository.dart';
import '../../domain/entities/citizen_profile_update.dart';
import '../../domain/repositories/citizen_profile_repository.dart';

final citizenProfileRepositoryProvider = Provider<CitizenProfileRepository>(
  (ref) => FirebaseCitizenProfileRepository(),
);

class CitizenProfileEditor extends ConsumerStatefulWidget {
  final UserEntity user;

  const CitizenProfileEditor({super.key, required this.user});

  static Future<void> show(BuildContext context, UserEntity user) {
    return EcoBottomSheet.show<void>(
      context: context,
      title: 'Mis datos personales',
      scrollable: true,
      children: [CitizenProfileEditor(user: user)],
    );
  }

  @override
  ConsumerState<CitizenProfileEditor> createState() =>
      _CitizenProfileEditorState();
}

class _CitizenProfileEditorState extends ConsumerState<CitizenProfileEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phoneNumber);
  Uint8List? _photo;
  String? _error;
  bool _saving = false;
  bool _picking = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    final selected = await ref
        .read(mediaPickerServiceProvider)
        .pickImageFromGallery(maxWidth: 768);
    if (!mounted) return;
    setState(() {
      _picking = false;
      _error = selected.errorMessage;
      final bytes = selected.bytes;
      if (bytes == null) return;
      if (CitizenProfileUpdate.photoContentType(bytes) == null) {
        _error = 'Elige una imagen JPG, PNG o WebP de hasta 5 MB.';
        return;
      }
      _photo = bytes;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final auth = ref.read(authViewModelProvider.notifier);
    final repository = ref.read(citizenProfileRepositoryProvider);
    final result = await repository.update(
      widget.user.id,
      CitizenProfileUpdate(name: _name.text, phone: _phone.text, photo: _photo),
    );
    final profile = result.dataOrNull;
    if (profile != null) auth.applySavedProfile(profile);
    if (!mounted) return;
    if (profile != null) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Datos guardados.')));
      return;
    }
    setState(() {
      _saving = false;
      _error = result.failureOrNull?.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CitizenProfileAvatar(
              url: widget.user.photoUrl,
              bytes: _photo,
            ),
          ),
          TextButton.icon(
            onPressed: _saving || _picking ? null : _pickPhoto,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(_picking ? 'Abriendo galería…' : 'Cambiar foto'),
          ),
          IgnorePointer(
            ignoring: _saving,
            child: Column(
              children: [
                AuthTextField(
                  label: 'Nombre completo',
                  hintText: 'Ingresa tu nombre',
                  icon: Icons.person_outline,
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  validator: CitizenProfileUpdate.validateName,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  label: 'Teléfono',
                  hintText: 'Opcional',
                  icon: Icons.phone_outlined,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  validator: CitizenProfileUpdate.validatePhone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ProfileDataRow(
            icon: Icons.email_outlined,
            label: 'Correo electrónico',
            value: widget.user.email,
          ),
          const SizedBox(height: 12),
          const ProfileDataRow(
            icon: Icons.badge_outlined,
            label: 'Rol en la plataforma',
            value: 'Ciudadano Activo',
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving || _picking ? null : _save,
            child: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
          ),
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class CitizenProfileAvatar extends StatelessWidget {
  final String? url;
  final Uint8List? bytes;
  final double size;

  const CitizenProfileAvatar({super.key, this.url, this.bytes, this.size = 76});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.person_rounded,
      size: size * .6,
      color: const Color(0xFF8C98A9),
    );
    return ClipOval(
      child: ColoredBox(
        color: const Color(0xFFE2E8F0),
        child: SizedBox.square(
          dimension: size,
          child: bytes == null
              ? MediaImage(location: url, placeholder: fallback)
              : Image.memory(
                  bytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}
