import 'package:flutter/material.dart';

import '../../domain/entities/municipal_crew_entity.dart';

class AdminCrewCard extends StatelessWidget {
  const AdminCrewCard({super.key, required this.crew, required this.onTap});

  final MunicipalCrewEntity crew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final truck = [
      crew.vehicleCode,
      crew.vehiclePlate,
    ].where((value) => value.isNotEmpty).join(' · ');
    final count = crew.crewMembersCount;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAF4EE),
          foregroundColor: Color(0xFF0A5835),
          child: Icon(Icons.groups_outlined),
        ),
        title: Text(
          crew.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count == 1 ? '1 integrante' : '$count integrantes'),
            if (truck.isNotEmpty)
              Text(truck, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            AdminCrewStatusLabel(crew.status),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class AdminCrewStatusLabel extends StatelessWidget {
  const AdminCrewStatusLabel(this.status, {super.key, this.showIcon = false});

  final MunicipalCrewStatus status;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MunicipalCrewStatus.available => const Color(0xFF0A5835),
      MunicipalCrewStatus.onRoute => const Color(0xFF1D4ED8),
      MunicipalCrewStatus.maintenance => const Color(0xFF9A3412),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: showIcon ? 10 : 8,
          vertical: showIcon ? 5 : 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                switch (status) {
                  MunicipalCrewStatus.available => Icons.check_circle_outline,
                  MunicipalCrewStatus.onRoute => Icons.local_shipping_outlined,
                  MunicipalCrewStatus.maintenance => Icons.build_outlined,
                },
                color: color,
                size: 16,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                status.label,
                style: TextStyle(
                  color: color,
                  fontSize: showIcon ? 14 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
