import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/citizen_push_service.dart';
import '../../../../core/widgets/eco_bottom_sheet.dart';
import '../../domain/entities/citizen_notification.dart';
import '../viewmodels/citizen_notifications_providers.dart';

class CitizenNotificationPreferencesSheet extends ConsumerWidget {
  final String userId;

  const CitizenNotificationPreferencesSheet({super.key, required this.userId});

  static Future<void> show(BuildContext context, String userId) {
    return EcoBottomSheet.show<void>(
      context: context,
      title: 'Preferencias de Notificaciones',
      scrollable: true,
      children: [CitizenNotificationPreferencesSheet(userId: userId)],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = citizenNotificationPreferencesProvider(userId);
    return ref
        .watch(provider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Column(
            children: [
              const Text('No se pudieron cargar tus preferencias.'),
              TextButton(
                onPressed: () => ref.invalidate(provider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
          data: (preferences) =>
              _PreferencesForm(userId: userId, initial: preferences),
        );
  }
}

class _PreferencesForm extends ConsumerStatefulWidget {
  final String userId;
  final CitizenNotificationPreferences initial;

  const _PreferencesForm({required this.userId, required this.initial});

  @override
  ConsumerState<_PreferencesForm> createState() => _PreferencesFormState();
}

class _PreferencesFormState extends ConsumerState<_PreferencesForm> {
  late var _preferences = widget.initial;
  bool _saving = false;
  bool _activatingPush = false;
  String? _pushStatus;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(citizenNotificationRepositoryProvider)
          .savePreferences(widget.userId, _preferences);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Preferencias de notificación guardadas.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No se pudieron guardar tus preferencias. Inténtalo de nuevo.';
      });
    }
  }

  Future<void> _activatePush() async {
    setState(() {
      _activatingPush = true;
      _pushStatus = null;
    });
    String message;
    try {
      final enabled = await CitizenPushService().sync(
        widget.userId,
        requestPermission: true,
      );
      message = enabled
          ? 'Notificaciones push activadas en este dispositivo.'
          : 'Permite las notificaciones de EcoRoute en los ajustes de Android.';
    } catch (_) {
      message = 'No se pudo activar el push. Inténtalo de nuevo.';
    }
    if (!mounted) return;
    setState(() {
      _activatingPush = false;
      _pushStatus = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Actualizaciones de reportes'),
          subtitle: const Text(
            'Recibe avisos sobre la atención de tus reportes.',
          ),
          value: _preferences.reportUpdates,
          onChanged: _saving
              ? null
              : (value) => setState(() {
                  _preferences = _preferences.copyWith(reportUpdates: value);
                }),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Camión recolector cerca'),
          subtitle: const Text('Avisos de cercanía · Próximamente'),
          value: _preferences.nearbyTruck,
          onChanged: _saving
              ? null
              : (value) => setState(() {
                  _preferences = _preferences.copyWith(nearbyTruck: value);
                }),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Campañas y noticias ambientales'),
          subtitle: const Text('Avisos de campañas · Próximamente'),
          value: _preferences.campaigns,
          onChanged: _saving
              ? null
              : (value) => setState(() {
                  _preferences = _preferences.copyWith(campaigns: value);
                }),
        ),
        if (CitizenPushService.isSupported) ...[
          const Divider(),
          TextButton.icon(
            onPressed: _saving || _activatingPush ? null : _activatePush,
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(
              _activatingPush
                  ? 'Activando…'
                  : 'Activar push en este dispositivo',
            ),
          ),
          if (_pushStatus case final status?) Text(status),
        ],
        if (_error case final error?)
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _saving || _activatingPush ? null : _save,
          child: Text(_saving ? 'Guardando…' : 'Guardar preferencias'),
        ),
      ],
    );
  }
}
