import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Modelo de datos para una opción de notificación configurable.
class NotificationOptionItem {
  final String title;
  final String subtitle;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  const NotificationOptionItem({
    required this.title,
    required this.subtitle,
    required this.initialValue,
    this.onChanged,
  });
}

/// Modal genérico de preferencias de notificaciones.
///
/// Principio OCP (Abierto/Cerrado) y DRY: Permite configurar opciones de notificación
/// para cualquier rol manteniendo una estructura y diseño visual estandarizados.
/// Ubicación: `lib/core/widgets/profile/profile_notifications_modal.dart`
/// Capa: Core (Widgets / Profile)
class ProfileNotificationsModal {
  static void show(
    BuildContext context, {
    required List<NotificationOptionItem> options,
    String snackBarMessage = 'Preferencias de notificación guardadas.',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _NotificationBottomSheetContent(
          options: options,
          snackBarMessage: snackBarMessage,
        );
      },
    );
  }
}

class _NotificationBottomSheetContent extends StatefulWidget {
  final List<NotificationOptionItem> options;
  final String snackBarMessage;

  const _NotificationBottomSheetContent({
    required this.options,
    required this.snackBarMessage,
  });

  @override
  State<_NotificationBottomSheetContent> createState() =>
      _NotificationBottomSheetContentState();
}

class _NotificationBottomSheetContentState
    extends State<_NotificationBottomSheetContent> {
  late List<bool> _values;

  @override
  void initState() {
    super.initState();
    _values = widget.options.map((o) => o.initialValue).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Preferencias de Notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < widget.options.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _values[i],
              onChanged: (val) {
                setState(() => _values[i] = val);
                widget.options[i].onChanged?.call(val);
              },
              activeThumbColor: AppColors.primary,
              title: Text(
                widget.options[i].title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                widget.options[i].subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(widget.snackBarMessage),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Guardar preferencias',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

