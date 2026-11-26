import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/cajamarca_urban_zones.dart';
import '../../../routes/domain/collection_route.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import 'admin_reports_viewmodel.dart';

final eligibleRouteReportsProvider =
    Provider.autoDispose<AsyncValue<Map<CajamarcaZone, List<CollectionStop>>>>((
      ref,
    ) {
      return ref
          .watch(urbanReportsProvider)
          .whenData(
            (zones) => {
              for (final entry in zones.entries)
                entry.key: [
                  for (final report in entry.value)
                    if (report.status.toDbString() == 'pending' &&
                        report.collectionRouteId == null &&
                        report.assignedToTeamId?.isNotEmpty != true &&
                        report.assignedStaffIds.isEmpty)
                      CollectionStop.fromReport(report),
                ],
            },
          );
    });

final routeCrewsProvider =
    FutureProvider.autoDispose<List<MunicipalCrewEntity>>((ref) async {
      final result = await ref.watch(getCrewsUseCaseProvider)();
      return result.fold(
        onSuccess: (crews) => crews
            .where(
              (crew) =>
                  !crew.vehicleOnly &&
                  crew.isAvailable &&
                  crew.status != MunicipalCrewStatus.maintenance &&
                  crew.effectiveLeaderId != null &&
                  crew.vehiclePlate.trim().isNotEmpty,
            )
            .toList(),
        onFailure: (failure) => throw StateError(failure.message),
      );
    });
