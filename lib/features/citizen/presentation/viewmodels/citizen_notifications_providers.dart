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

final citizenUnreadCountProvider = StreamProvider.autoDispose
    .family<int, (String, int)>(
      (ref, args) => ref
          .watch(citizenNotificationRepositoryProvider)
          .watchUnreadCount(args.$1, limit: args.$2),
    );
