import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/features/admin/data/models/municipal_crew_dto.dart';
import 'package:ecoroute/features/admin/domain/entities/municipal_crew_entity.dart';

void main() {
  group('MunicipalCrewDto Unit Tests', () {
    const testEntity = MunicipalCrewEntity(
      id: 'crew-01',
      name: 'Cuadrilla Los Olivos',
      zone: 'Sector 2 (Av. Angélica Gamarra)',
      leadStaffName: 'Pedro Martínez',
      vehicleCode: 'Camión #08',
      vehiclePlate: 'ECR-771',
      vehicleType: 'Camión Compactador 15m³',
      crewMembersCount: 4,
      activeTasksCount: 1,
      isAvailable: true,
      status: MunicipalCrewStatus.onRoute,
      latitude: -12.0010,
      longitude: -77.0650,
    );

    test('fromDomain & toDomain realizan conversión bidireccional consistente', () {
      final dto = MunicipalCrewDto.fromDomain(testEntity);

      expect(dto.id, testEntity.id);
      expect(dto.name, testEntity.name);
      expect(dto.zone, testEntity.zone);
      expect(dto.leadStaffName, testEntity.leadStaffName);
      expect(dto.vehicleCode, testEntity.vehicleCode);
      expect(dto.vehiclePlate, testEntity.vehiclePlate);
      expect(dto.vehicleType, testEntity.vehicleType);
      expect(dto.crewMembersCount, 4);
      expect(dto.activeTasksCount, 1);
      expect(dto.isAvailable, true);
      expect(dto.status, 'onRoute');
      expect(dto.latitude, -12.0010);
      expect(dto.longitude, -77.0650);

      final entityBack = dto.toDomain();
      expect(entityBack, equals(testEntity));
    });

    test('fromMap parsea mapa de Firestore con campo location anidado', () {
      final map = {
        'name': 'Cuadrilla Surquillo',
        'zone': 'Sector Principal',
        'leadStaffName': 'Rosa Flores',
        'vehicleCode': 'Camión #03',
        'vehiclePlate': 'ECR-300',
        'vehicleType': 'Furgón Barrendero Ligero',
        'crewMembersCount': 2,
        'activeTasksCount': 0,
        'isAvailable': true,
        'status': 'available',
        'location': {
          'latitude': -12.1120,
          'longitude': -77.0250,
        },
        'createdAt': Timestamp.fromDate(DateTime(2025, 2, 1)),
      };

      final dto = MunicipalCrewDto.fromMap(map, 'doc-surquillo-1');

      expect(dto.id, 'doc-surquillo-1');
      expect(dto.name, 'Cuadrilla Surquillo');
      expect(dto.latitude, -12.1120);
      expect(dto.longitude, -77.0250);
      expect(dto.status, 'available');
      expect(dto.createdAt, DateTime(2025, 2, 1));
    });

    test('fromMap aplica valores por defecto seguros ante campos nulos', () {
      final emptyMap = <String, dynamic>{};

      final dto = MunicipalCrewDto.fromMap(emptyMap, 'fallback-id');

      expect(dto.id, 'fallback-id');
      expect(dto.name, 'Cuadrilla Municipal');
      expect(dto.zone, 'Sector General');
      expect(dto.crewMembersCount, 3);
      expect(dto.activeTasksCount, 0);
      expect(dto.isAvailable, true);
      expect(dto.status, 'available');
      expect(dto.latitude, -12.0463);
      expect(dto.longitude, -77.0427);
    });

    test('toMap genera mapa con timestamps y estructura adecuada para Firestore', () {
      final dto = MunicipalCrewDto.fromDomain(
        testEntity,
        createdAt: DateTime(2025, 3, 10, 8, 30),
      );

      final map = dto.toMap();

      expect(map['id'], 'crew-01');
      expect(map['name'], 'Cuadrilla Los Olivos');
      expect(map['vehiclePlate'], 'ECR-771');
      expect(map['status'], 'onRoute');
      expect(map['location']['latitude'], -12.0010);
      expect(map['location']['longitude'], -77.0650);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<FieldValue>());
    });

    test('MunicipalCrewStatus fromString y toDbString operan coherentemente', () {
      expect(MunicipalCrewStatus.fromString('onRoute'), MunicipalCrewStatus.onRoute);
      expect(MunicipalCrewStatus.fromString('on_route'), MunicipalCrewStatus.onRoute);
      expect(MunicipalCrewStatus.fromString('maintenance'), MunicipalCrewStatus.maintenance);
      expect(MunicipalCrewStatus.fromString('available'), MunicipalCrewStatus.available);
      expect(MunicipalCrewStatus.fromString('unknown_status'), MunicipalCrewStatus.available);

      expect(MunicipalCrewStatus.available.toDbString(), 'available');
      expect(MunicipalCrewStatus.onRoute.toDbString(), 'onRoute');
      expect(MunicipalCrewStatus.maintenance.toDbString(), 'maintenance');
    });
  });
}

