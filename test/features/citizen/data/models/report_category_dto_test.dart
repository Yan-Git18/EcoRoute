import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/features/citizen/data/models/report_category_dto.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_category_entity.dart';

void main() {
  group('ReportCategoryDto', () {
    test('fromFirestore deserializa correctamente un Map', () {
      final map = {
        'name': 'Contenedor lleno',
        'description': 'Contenedor público sobrepasado',
        'icon': 'delete_sweep_rounded',
        'defaultPriority': 'medium',
        'slaHours': 12,
        'order': 2,
        'isActive': true,
      };

      final dto = ReportCategoryDto.fromFirestore('cat-01', map);

      expect(dto.id, 'cat-01');
      expect(dto.name, 'Contenedor lleno');
      expect(dto.description, 'Contenedor público sobrepasado');
      expect(dto.icon, 'delete_sweep_rounded');
      expect(dto.defaultPriority, 'medium');
      expect(dto.slaHours, 12);
      expect(dto.order, 2);
      expect(dto.isActive, isTrue);
    });

    test('toMap serializa correctamente los campos', () {
      const dto = ReportCategoryDto(
        id: 'cat-02',
        name: 'Basura en vía pública',
        description: 'Desechos en la pista',
        icon: 'cleaning_services_rounded',
        defaultPriority: 'high',
        slaHours: 6,
        order: 1,
      );

      final map = dto.toMap();

      expect(map['name'], 'Basura en vía pública');
      expect(map['defaultPriority'], 'high');
      expect(map['slaHours'], 6);
      expect(map['order'], 1);
      expect(map['isActive'], isTrue);
    });

    test('toEntity retorna la misma instancia extendida de ReportCategoryEntity', () {
      const dto = ReportCategoryDto(
        id: 'cat-03',
        name: 'Punto reciclaje',
        description: 'Punto de reciclaje roto',
        icon: 'recycling_rounded',
        defaultPriority: 'low',
        slaHours: 48,
        order: 4,
      );

      final entity = dto.toEntity();
      expect(entity, isA<ReportCategoryEntity>());
      expect(entity.id, 'cat-03');
    });

    test('fromEntity convierte una entidad a DTO', () {
      const entity = ReportCategoryEntity(
        id: 'cat-04',
        name: 'Otro problema',
        description: 'Incidencia no listada',
        icon: 'warning_amber_rounded',
        defaultPriority: 'low',
        slaHours: 48,
        order: 5,
      );

      final dto = ReportCategoryDto.fromEntity(entity);
      expect(dto.id, 'cat-04');
      expect(dto.name, 'Otro problema');
      expect(dto.slaHours, 48);
    });
  });
}

