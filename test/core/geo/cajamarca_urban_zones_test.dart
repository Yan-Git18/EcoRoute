import 'package:ecoroute/core/geo/cajamarca_urban_zones.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Ubica un punto interior en cada sector urbano', () {
    expect(CajamarcaZone.values, hasLength(6));
    expect(CajamarcaUrbanZones.zoneAt(-7.158, -78.518), CajamarcaZone.central);
    expect(
      CajamarcaUrbanZones.zoneAt(-7.151, -78.527),
      CajamarcaZone.northwest,
    );
    expect(
      CajamarcaUrbanZones.zoneAt(-7.148, -78.496),
      CajamarcaZone.northeast,
    );
    expect(
      CajamarcaUrbanZones.zoneAt(-7.168, -78.524),
      CajamarcaZone.southwest,
    );
    expect(CajamarcaUrbanZones.zoneAt(-7.169, -78.503), CajamarcaZone.east);
    expect(
      CajamarcaUrbanZones.zoneAt(-7.178, -78.505),
      CajamarcaZone.southeast,
    );
  });

  test('Excluye Los Baños del Inca, el exterior y coordenadas inválidas', () {
    expect(CajamarcaUrbanZones.zoneAt(-7.166, -78.454), isNull);
    expect(CajamarcaUrbanZones.zoneAt(-7.165, -78.529), isNull);
    expect(CajamarcaUrbanZones.zoneAt(0, 0), isNull);
    expect(CajamarcaUrbanZones.zoneAt(double.nan, -78.518), isNull);
  });

  test('Asigna una sola zona a los puntos sobre un límite compartido', () {
    expect(CajamarcaUrbanZones.zoneAt(-7.158, -78.508), CajamarcaZone.central);
    expect(
      CajamarcaUrbanZones.zoneAt(-7.1782956, -78.4963841),
      CajamarcaZone.east,
    );
  });
}
