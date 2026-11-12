import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/errors/failures.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/admin/domain/entities/municipal_crew_entity.dart';
import 'package:ecoroute/features/admin/domain/repositories/admin_repository.dart';
import 'package:ecoroute/features/admin/domain/usecases/create_crew_use_case.dart';
import 'package:ecoroute/features/admin/domain/usecases/delete_crew_use_case.dart';
import 'package:ecoroute/features/admin/domain/usecases/get_crews_use_case.dart';
import 'package:ecoroute/features/admin/domain/usecases/update_crew_use_case.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';

class FakeAdminRepository implements AdminRepository {
  List<MunicipalCrewEntity> crews = [];
  bool getCrewsCalled = false;
  bool createCrewCalled = false;
  bool updateCrewCalled = false;
  bool deleteCrewCalled = false;

  @override
  Future<Result<List<MunicipalCrewEntity>>> getAvailableCrews() async {
    getCrewsCalled = true;
    return Success(crews);
  }

  @override
  Future<Result<MunicipalCrewEntity>> createCrew(MunicipalCrewEntity crew) async {
    createCrewCalled = true;
    final created = crew.copyWith(id: 'generated-${crews.length + 1}');
    crews.add(created);
    return Success(created);
  }

  @override
  Future<Result<MunicipalCrewEntity>> updateCrew(MunicipalCrewEntity crew) async {
    updateCrewCalled = true;
    final idx = crews.indexWhere((c) => c.id == crew.id);
    if (idx >= 0) {
      crews[idx] = crew;
    }
    return Success(crew);
  }

  @override
  Future<Result<void>> deleteCrew(String crewId) async {
    deleteCrewCalled = true;
    crews.removeWhere((c) => c.id == crewId);
    return const Success(null);
  }

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async => const Success([]);

  @override
  Future<Result<ReportEntity>> assignReportToCrew({
    required String reportId,
    required MunicipalCrewEntity crew,
    required String adminId,
    required String adminName,
    ReportPriority? priority,
    String? instructions,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<ReportEntity>> updateReportPriority({
    required String reportId,
    required ReportPriority priority,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<UserEntity>>> getStaffMembers() async => const Success([]);

  @override
  Future<Result<UserEntity?>> searchUserByExactEmail(String email) async => const Success(null);

  @override
  Future<Result<void>> updateUserRole({
    required String userId,
    required UserRole newRole,
    String? teamId,
  }) async => const Success(null);
}

void main() {
  group('Crew UseCases Unit Tests', () {
    late FakeAdminRepository repository;
    const testCrew = MunicipalCrewEntity(
      id: 'crew-1',
      name: 'Cuadrilla Test',
      zone: 'Sector Central',
      leadStaffName: 'Supervisor Test',
      vehicleCode: 'Camión #01',
      vehiclePlate: 'ECR-111',
      crewMembersCount: 3,
    );

    setUp(() {
      repository = FakeAdminRepository();
    });

    test('GetCrewsUseCase delega consulta al repositorio', () async {
      final useCase = GetCrewsUseCase(repository);
      final result = await useCase();

      expect(repository.getCrewsCalled, isTrue);
      expect(result, isA<Success<List<MunicipalCrewEntity>>>());
    });

    group('CreateCrewUseCase', () {
      test('rechaza cuadrilla con nombre menor a 3 caracteres', () async {
        final useCase = CreateCrewUseCase(repository);
        final result = await useCase(testCrew.copyWith(name: 'Ab'));

        expect(result, isA<FailureResult<MunicipalCrewEntity>>());
        final failure = (result as FailureResult).failure;
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, contains('al menos 3 caracteres'));
      });

      test('rechaza cuadrilla con sector o zona vacía', () async {
        final useCase = CreateCrewUseCase(repository);
        final result = await useCase(testCrew.copyWith(zone: '   '));

        expect(result, isA<FailureResult<MunicipalCrewEntity>>());
        final failure = (result as FailureResult).failure;
        expect(failure.message, contains('zona o sector'));
      });

      test('rechaza cuadrilla con líder vacío', () async {
        final useCase = CreateCrewUseCase(repository);
        final result = await useCase(testCrew.copyWith(leadStaffName: ''));

        expect(result, isA<FailureResult<MunicipalCrewEntity>>());
        final failure = (result as FailureResult).failure;
        expect(failure.message, contains('responsable o líder'));
      });

      test('rechaza cuadrilla con placa inválida', () async {
        final useCase = CreateCrewUseCase(repository);
        final result = await useCase(testCrew.copyWith(vehiclePlate: 'E'));

        expect(result, isA<FailureResult<MunicipalCrewEntity>>());
        final failure = (result as FailureResult).failure;
        expect(failure.message, contains('placa vehicular'));
      });

      test('rechaza cuadrilla con menos de 1 integrante', () async {
        final useCase = CreateCrewUseCase(repository);
        final result = await useCase(testCrew.copyWith(crewMembersCount: 0));

        expect(result, isA<FailureResult<MunicipalCrewEntity>>());
        final failure = (result as FailureResult).failure;
        expect(failure.message, contains('al menos 1 integrante'));
      });

      test('crea cuadrilla válida exitosamente en el repositorio', () async {
        final useCase = CreateCrewUseCase(repository);
        final result = await useCase(testCrew);

        expect(repository.createCrewCalled, isTrue);
        expect(result, isA<Success<MunicipalCrewEntity>>());
        expect((result as Success).data.name, 'Cuadrilla Test');
      });
    });

    group('UpdateCrewUseCase', () {
      test('falla si el id está vacío', () async {
        final useCase = UpdateCrewUseCase(repository);
        final result = await useCase(testCrew.copyWith(id: ''));

        expect(result, isA<FailureResult<MunicipalCrewEntity>>());
      });

      test('falla si el nombre está vacío', () async {
        final useCase = UpdateCrewUseCase(repository);
        final result = await useCase(testCrew.copyWith(name: ' '));

        expect(result, isA<FailureResult<MunicipalCrewEntity>>());
      });

      test('falla si la zona está vacía', () async {
        final useCase = UpdateCrewUseCase(repository);
        final result = await useCase(testCrew.copyWith(zone: ' '));

        expect(result, isA<FailureResult<MunicipalCrewEntity>>());
      });

      test('actualiza cuadrilla válida exitosamente', () async {
        repository.crews = [testCrew];
        final useCase = UpdateCrewUseCase(repository);
        final result = await useCase(testCrew.copyWith(zone: 'Nuevo Sector'));

        expect(repository.updateCrewCalled, isTrue);
        expect(result, isA<Success<MunicipalCrewEntity>>());
        expect((result as Success).data.zone, 'Nuevo Sector');
      });
    });

    group('DeleteCrewUseCase', () {
      test('falla si el id está vacío', () async {
        final useCase = DeleteCrewUseCase(repository);
        final result = await useCase('');

        expect(result, isA<FailureResult<void>>());
      });

      test('elimina cuadrilla del repositorio exitosamente', () async {
        repository.crews = [testCrew];
        final useCase = DeleteCrewUseCase(repository);
        final result = await useCase('crew-1');

        expect(repository.deleteCrewCalled, isTrue);
        expect(result, isA<Success<void>>());
        expect(repository.crews, isEmpty);
      });
    });
  });
}

