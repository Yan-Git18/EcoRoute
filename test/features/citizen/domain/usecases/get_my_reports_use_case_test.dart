import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_category_entity.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/citizen/domain/repositories/report_repository.dart';
import 'package:ecoroute/features/citizen/domain/usecases/get_my_reports_use_case.dart';

class FakeReportRepository implements ReportRepository {
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
    List<List<int>>? multipleImageBytes,
    List<String>? localImagePaths,
  }) async {
    return Success(report);
  }

  @override
  Future<Result<List<ReportEntity>>> getMyReports(String citizenId) async {
    return Success(reportsToReturn);
  }

  @override
  Future<Result<ReportEntity>> getReportById(String reportId) async {
    final match = reportsToReturn.firstWhere((r) => r.id == reportId);
    return Success(match);
  }

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async {
    return Success(reportsToReturn);
  }

  @override
  Future<Result<ReportEntity>> cancelReport({required String reportId, String? reason}) async {
    final match = reportsToReturn.firstWhere((r) => r.id == reportId);
    return Success(match.copyWith(status: ReportStatus.cancelled));
  }
}

void main() {
  late FakeReportRepository fakeRepository;
  late GetMyReportsUseCase useCase;

  setUp(() {
    fakeRepository = FakeReportRepository();
    useCase = GetMyReportsUseCase(fakeRepository);
  });

  test('debe retornar lista vacía si el usuario no tiene reportes generados', () async {
    fakeRepository.reportsToReturn = [];

    final result = await useCase('user-123');

    expect(result.isSuccess, true);
    expect(result.dataOrNull, isEmpty);
  });

  test('debe retornar los reportes del ciudadano cuando existen', () async {
    final testReport = ReportEntity(
      id: 'rep-001',
      reportNumber: '#0012',
      citizenId: 'user-123',
      citizenName: 'Carlos Gómez',
      categoryId: 'waste_accumulation',
      categoryName: 'Acumulación de basura',
      categoryIcon: 'delete_outline_rounded',
      description: 'Bolsas acumuladas en vía pública.',
      priority: ReportPriority.high,
      status: ReportStatus.inProgress,
      latitude: -12.046,
      longitude: -77.042,
      address: 'Av. Los Incas 412',
      imageUrls: const [],
      createdAt: DateTime.now(),
    );

    fakeRepository.reportsToReturn = [testReport];

    final result = await useCase('user-123');

    expect(result.isSuccess, true);
    expect(result.dataOrNull?.length, 1);
    expect(result.dataOrNull?.first.reportNumber, '#0012');
  });
}
