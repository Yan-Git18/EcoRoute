import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_category_entity.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/citizen/domain/repositories/report_repository.dart';
import 'package:ecoroute/features/citizen/domain/usecases/get_all_reports_use_case.dart';

class MockReportRepository implements ReportRepository {
  List<ReportEntity> reportsToReturn = [];

  @override
  Future<Result<List<ReportCategoryEntity>>> getCategories() async {
    return const Success(ReportCategoryEntity.defaultCategories);
  }

  @override
  Future<Result<ReportEntity>> createReport({
    required ReportEntity report,
    List<int>? imageBytes,
    String? imageFileName,
  }) async {
    return Success(report);
  }

  @override
  Future<Result<List<ReportEntity>>> getMyReports(String citizenId) async {
    return Success(reportsToReturn);
  }

  @override
  Future<Result<ReportEntity>> getReportById(String reportId) async {
    return Success(reportsToReturn.first);
  }

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async {
    return Success(reportsToReturn);
  }
}

void main() {
  late MockReportRepository repository;
  late GetAllReportsUseCase useCase;

  setUp(() {
    repository = MockReportRepository();
    useCase = GetAllReportsUseCase(repository);
  });

  test('debe retornar la lista completa de reportes comunitarios con Success', () async {
    final testReport = ReportEntity(
      id: 'r-1',
      reportNumber: '#REP-001',
      citizenId: 'u-1',
      citizenName: 'Carlos',
      categoryId: 'waste_accumulation',
      categoryName: 'Acumulación de basura',
      categoryIcon: 'delete_outline_rounded',
      description: 'Basura en la esquina',
      priority: ReportPriority.high,
      status: ReportStatus.pending,
      latitude: -12.0463,
      longitude: -77.0427,
      address: 'Av. Abancay 123',
      imageUrls: const [],
      createdAt: DateTime.now(),
    );

    repository.reportsToReturn = [testReport];

    final result = await useCase();

    expect(result.isSuccess, isTrue);
    result.fold(
      onSuccess: (list) {
        expect(list.length, equals(1));
        expect(list.first.reportNumber, equals('#REP-001'));
        expect(list.first.priority, equals(ReportPriority.high));
      },
      onFailure: (_) => fail('Debería retornar Success'),
    );
  });
}
