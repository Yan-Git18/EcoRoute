import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_citizen_notification_repository.dart';
import '../../domain/entities/citizen_notification.dart';
import '../../domain/repositories/citizen_notification_repository.dart';

final citizenNotificationRepositoryProvider =
    Provider<CitizenNotificationRepository>(
      (ref) => FirebaseCitizenNotificationRepository(),
    );

final citizenNotificationPreferencesProvider = FutureProvider.autoDispose
    .family<CitizenNotificationPreferences, String>(
      (ref, userId) => ref
          .watch(citizenNotificationRepositoryProvider)
          .getPreferences(userId),
    );

final citizenInboxProvider = StreamProvider.autoDispose
    .family<List<CitizenNotification>, (String, int)>(
      (ref, args) => ref
          .watch(citizenNotificationRepositoryProvider)
          .watchInbox(args.$1, args.$2),
    );

final citizenHasUnreadProvider = StreamProvider.autoDispose
    .family<bool, String>(
      (ref, userId) =>
          ref.watch(citizenNotificationRepositoryProvider).watchUnread(userId),
    );
