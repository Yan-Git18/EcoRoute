import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/geo/cajamarca_urban_zones.dart';

const adminZoneColors = {
  CajamarcaZone.central: Color(0xFFC02668),
  CajamarcaZone.northwest: Color(0xFF805124),
  CajamarcaZone.northeast: Color(0xFF5B42A6),
  CajamarcaZone.southwest: Color(0xFF9C6700),
  CajamarcaZone.southeast: Color(0xFF087849),
};

class AdminMapZoneLayer extends StatelessWidget {
  const AdminMapZoneLayer({super.key, required this.selectedZone});

  final CajamarcaZone? selectedZone;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: PolygonLayer(
        polygons: [
          for (final zone in CajamarcaZone.values)
            for (final polygon in zone.polygons)
              Polygon(
                points: polygon.first,
                holePointsList: polygon.skip(1).toList(),
                color: adminZoneColors[zone]!.withValues(
                  alpha: zone == selectedZone ? 0.32 : 0.18,
                ),
                borderColor: adminZoneColors[zone]!,
                borderStrokeWidth: zone == selectedZone ? 3 : 1.5,
              ),
        ],
      ),
    );
  }
}
