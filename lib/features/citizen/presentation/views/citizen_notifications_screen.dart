import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../domain/entities/citizen_notification.dart';
import '../../domain/entities/report_entity.dart';
import '../viewmodels/citizen_notifications_providers.dart';

class CitizenNotificationsScreen extends ConsumerStatefulWidget {
  const CitizenNotificationsScreen({super.key});

  @override
  ConsumerState<CitizenNotificationsScreen> createState() =>
      _CitizenNotificationsScreenState();
}

class _CitizenNotificationsScreenState
    extends ConsumerState<CitizenNotificationsScreen> {
  static const _pageSize = 30;
  int _limit = _pageSize;

  Future<void> _markRead(String userId, String notificationId) async {
    try {
      await ref
          .read(citizenNotificationRepositoryProvider)
          .markRead(userId, notificationId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo marcar el aviso como leído.')),
      );
    }
  }

  void _open(String userId, CitizenNotification notification) {
    if (!notification.isRead) unawaited(_markRead(userId, notification.id));
    context.push(RouteNames.citizenReportLocation(notification.reportId));
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(
      authViewModelProvider.select((state) => state.user?.id),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.citizenHome),
        ),
      ),
      body: userId == null ? const SizedBox.shrink() : _buildInbox(userId),
    );
  }

  Widget _buildInbox(String userId) {
    final provider = citizenInboxProvider((userId, _limit));
    return ref
        .watch(provider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudieron cargar las notificaciones.'),
                TextButton(
                  onPressed: () => ref.invalidate(provider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('Aún no tienes notificaciones.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length + (items.length == _limit ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return Center(
                    child: TextButton(
                      onPressed: () => setState(() => _limit += _pageSize),
                      child: const Text('Cargar avisos anteriores'),
                    ),
                  );
                }
                final item = items[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.status.backgroundColor,
                    foregroundColor: item.status.color,
                    child: Icon(item.status.icon),
                  ),
                  title: Text(
                    'Reporte ${item.reportNumber}',
                    style: item.isRead
                        ? null
                        : const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${item.status.displayLabel} · ${DateFormatter.formatShortDate(item.createdAt)}',
                  ),
                  trailing: item.isRead
                      ? null
                      : const Tooltip(
                          message: 'Sin leer',
                          child: Icon(Icons.circle, size: 10),
                        ),
                  onTap: () => _open(userId, item),
                );
              },
            );
          },
        );
  }
}
