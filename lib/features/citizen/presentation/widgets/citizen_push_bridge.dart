import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/citizen_push_service.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class CitizenPushBridge extends ConsumerStatefulWidget {
  final GoRouter router;
  final Widget child;

  const CitizenPushBridge({
    super.key,
    required this.router,
    required this.child,
  });

  @override
  ConsumerState<CitizenPushBridge> createState() => _CitizenPushBridgeState();
}

class _CitizenPushBridgeState extends ConsumerState<CitizenPushBridge>
    with WidgetsBindingObserver {
  final _push = CitizenPushService();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  String? _pendingRecipient;

  String? get _citizenId {
    final user = ref.read(authViewModelProvider).user;
    return user?.isCitizen == true ? user!.id : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(
      authViewModelProvider.select((state) {
        final user = state.user;
        return user?.isCitizen == true ? user!.id : null;
      }),
      (_, userId) {
        if (userId != null) {
          unawaited(_sync(userId));
          _openPendingInbox();
        }
      },
      fireImmediately: true,
    );
    _subscriptions.addAll([
      _push.tokenChanges.listen(_onTokenRefresh),
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpened),
      FirebaseMessaging.onMessage.listen(_onForegroundMessage),
    ]);
    unawaited(_restoreInitialMessage());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_citizenId case final userId?) unawaited(_sync(userId));
  }

  Future<void> _sync(String userId) async {
    try {
      await _push.sync(userId);
    } catch (_) {
      // El permiso y el registro se pueden reintentar desde el perfil.
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    final userId = _citizenId;
    if (userId == null) return;
    try {
      await _push.registerToken(userId, token);
    } catch (_) {
      // Se vuelve a sincronizar al reanudar la app.
    }
  }

  Future<void> _restoreInitialMessage() async {
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (mounted && message != null) _onOpened(message);
    } catch (_) {
      // La bandeja sigue disponible desde el inicio.
    }
  }

  void _onOpened(RemoteMessage message) {
    final recipient = message.data['recipientId'];
    if (message.data['type'] != 'report_status' || recipient is! String) return;
    _pendingRecipient = recipient;
    _openPendingInbox();
  }

  void _openPendingInbox() {
    final recipient = _pendingRecipient;
    final citizenId = _citizenId;
    if (recipient == null || citizenId == null) return;
    _pendingRecipient = null;
    if (recipient != citizenId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _citizenId == recipient) _openInbox();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _onForegroundMessage(RemoteMessage message) {
    final recipient = message.data['recipientId'];
    if (message.data['type'] != 'report_status' ||
        recipient is! String ||
        recipient != _citizenId) {
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: const Text('Tienes una actualización de EcoRoute.'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () {
            if (mounted && _citizenId == recipient) _openInbox();
          },
        ),
      ),
    );
  }

  void _openInbox() {
    final router = widget.router;
    if (router.state.uri.path != RouteNames.citizenNotifications) {
      unawaited(router.push<void>(RouteNames.citizenNotifications));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
