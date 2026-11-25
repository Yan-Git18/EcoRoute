import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/profile/profile_change_password_modal.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/repositories/firebase_admin_profile_repository.dart';
import '../../domain/repositories/admin_profile_repository.dart';
import '../widgets/admin_back_button.dart';

final adminProfileRepositoryProvider = Provider<AdminProfileRepository>(
  (ref) => const FirebaseAdminProfileRepository(),
);

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(
      authViewModelProvider.select((auth) => auth.user),
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AdminBackButton(),
        title: const Text('Mi perfil'),
      ),
      body: account == null || !account.isAdmin
          ? const Center(child: Text('Inicia sesión para ver tu perfil.'))
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _AdminProfileForm(
                  key: ValueKey(account.id),
                  account: account,
                ),
              ),
            ),
    );
  }
}

class _AdminProfileForm extends ConsumerStatefulWidget {
  const _AdminProfileForm({super.key, required this.account});

  final UserEntity account;

  @override
  ConsumerState<_AdminProfileForm> createState() => _AdminProfileFormState();
}

class _AdminProfileFormState extends ConsumerState<_AdminProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.account.name);
  late final _phone = TextEditingController(text: widget.account.phoneNumber);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (_busy || !_form.currentState!.validate()) return;
    final phone = _phone.text.trim();
    setState(() => _busy = true);
    final result = await ref
        .read(adminProfileRepositoryProvider)
        .saveContact(
          widget.account,
          name: _name.text.trim(),
          phone: phone.isEmpty ? null : phone,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (profile) {
        ref.read(authViewModelProvider.notifier).applySavedProfile(profile);
        _message('Datos actualizados.');
      },
      onFailure: (failure) => _message(failure.message),
    );
  }

  Future<void> _refreshEmail() async {
    final account = widget.account;
    setState(() => _busy = true);
    final result = await ref
        .read(adminProfileRepositoryProvider)
        .refreshEmail(account.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (email) {
        ref
            .read(authViewModelProvider.notifier)
            .applyVerifiedAdminEmail(account.id, email);
        _message(
          email == account.email
              ? 'El correo registrado está al día.'
              : 'Correo actualizado.',
        );
      },
      onFailure: (failure) => _message(failure.message),
    );
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Datos personales', style: titleStyle),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      final length = value?.trim().length ?? 0;
                      return length == 0 || length > 100
                          ? 'Escribe un nombre de hasta 100 caracteres.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => (value?.trim().length ?? 0) > 30
                        ? 'Escribe un teléfono de hasta 30 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _saveContact,
                    child: const Text('Guardar datos'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Correo electrónico'),
                subtitle: Text(account.email),
                trailing: Tooltip(
                  message: 'Comprobar correo confirmado',
                  child: TextButton(
                    onPressed: _busy ? null : _refreshEmail,
                    child: const Text('Comprobar'),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Cambiar correo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _busy
                    ? null
                    : () async {
                        final sent = await showDialog<bool>(
                          context: context,
                          builder: (_) =>
                              _ChangeAdminEmailDialog(account: account),
                        );
                        if (!mounted || sent != true) return;
                        _message(
                          'Confirma el enlace en tu nuevo correo y vuelve aquí para comprobar el cambio.',
                        );
                      },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Cambiar contraseña'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _busy || account.email.isEmpty
                    ? null
                    : () => ProfileChangePasswordModal.show(
                        context,
                        ref,
                        email: account.email,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChangeAdminEmailDialog extends ConsumerStatefulWidget {
  const _ChangeAdminEmailDialog({required this.account});

  final UserEntity account;

  @override
  ConsumerState<_ChangeAdminEmailDialog> createState() =>
      _ChangeAdminEmailDialogState();
}

class _ChangeAdminEmailDialogState
    extends ConsumerState<_ChangeAdminEmailDialog> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || !_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await ref
        .read(adminProfileRepositoryProvider)
        .requestEmailChange(
          widget.account.id,
          email: _email.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() => _sending = false);
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _sending = false;
        _error = result.failureOrNull?.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_sending,
      child: AlertDialog(
        title: const Text('Cambiar correo'),
        scrollable: true,
        content: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _email,
                enabled: !_sending,
                decoration: const InputDecoration(
                  labelText: 'Nuevo correo electrónico',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                    return 'Escribe un correo válido.';
                  }
                  return email.toLowerCase() ==
                          widget.account.email.toLowerCase()
                      ? 'Escribe un correo distinto al actual.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                enabled: !_sending,
                decoration: const InputDecoration(
                  labelText: 'Contraseña actual',
                ),
                obscureText: true,
                validator: (value) => value?.isNotEmpty == true
                    ? null
                    : 'Escribe tu contraseña actual.',
              ),
              if (_error case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _sending ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: Text(_sending ? 'Enviando…' : 'Enviar confirmación'),
          ),
        ],
      ),
    );
  }
}
