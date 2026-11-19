import 'report_entity.dart';

class CitizenNotification {
  final String id;
  final String reportId;
  final String reportNumber;
  final ReportStatus status;
  final DateTime createdAt;
  final bool isRead;

  const CitizenNotification({
    required this.id,
    required this.reportId,
    required this.reportNumber,
    required this.status,
    required this.createdAt,
    required this.isRead,
  });
}

class CitizenNotificationPreferences {
  final bool reportUpdates;
  final bool nearbyTruck;
  final bool campaigns;

  const CitizenNotificationPreferences({
    this.reportUpdates = true,
    this.nearbyTruck = true,
    this.campaigns = false,
  });

  CitizenNotificationPreferences copyWith({
    bool? reportUpdates,
    bool? nearbyTruck,
    bool? campaigns,
  }) {
    return CitizenNotificationPreferences(
      reportUpdates: reportUpdates ?? this.reportUpdates,
      nearbyTruck: nearbyTruck ?? this.nearbyTruck,
      campaigns: campaigns ?? this.campaigns,
    );
  }
}
