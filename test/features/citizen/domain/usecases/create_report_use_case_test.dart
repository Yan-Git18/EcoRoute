import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/errors/failures.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_category_entity.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/citizen/domain/repositories/report_repository.dart';
import 'package:ecoroute/features/citizen/domain/usecases/create_report_use_case.dart';

class FakeReportRepository implements ReportRepository {
  ReportEntity? lastCreatedReport;

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
    lastCreatedReport = report;
    return Success(report);
  }

  @override
  Future<Result<List<ReportEntity>>> getMyReports(String citizenId) async {
    return const Success([]);
  }

  @override
  Future<Result<ReportEntity>> getReportById(String reportId) async {
    if (lastCreatedReport != null) return Success(lastCreatedReport!);
    return const FailureResult(ServerFailure(message: 'No encontrado'));
  }
}

void main() {
  late FakeReportRepository fakeRepository;
  late CreateReportUseCase useCase;

  setUp(() {
    fakeRepository = FakeReportRepository();
    useCase = CreateReportUseCase(fakeRepository);
  });

  final validReport = ReportEntity(
    id: 'rep-1',
    reportNumber: '#0012',
    citizenId: 'user-1',
    citizenName: 'Carlos Gómez',
    categoryId: 'waste_accumulation',
    categoryName: 'Acumulación de basura',
    categoryIcon: 'delete_outline_rounded',
    description: 'Bolsas de basura acumuladas en la esquina.',
    priority: ReportPriority.high,
    status: ReportStatus.pending,
    latitude: -12.046,
    longitude: -77.042,
    address: 'Av. Las Palmeras 412',
    imageUrls: const [],
    createdAt: DateTime.now(),
  );

  test('debe retornar ValidationFailure si la categoría está vacía', () async {
    final invalidReport = ReportEntity(
      id: 'rep-1',
      reportNumber: '#0012',
      citizenId: 'user-1',
      citizenName: 'Carlos Gómez',
      categoryId: '',
      categoryName: '',
      categoryIcon: '',
      description: 'Bolsas de basura acumuladas en la esquina.',
      priority: ReportPriority.medium,
      status: ReportStatus.pending,
      latitude: -12.046,
      longitude: -77.042,
      address: 'Av. Las Palmeras 412',
      imageUrls: const [],
      createdAt: DateTime.now(),
    );

    final result = await useCase(report: invalidReport);

    expect(result.isFailure, true);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(result.failureOrNull?.message, contains('categoría'));
  });

  test('debe retornar ValidationFailure si la descripción tiene menos de 5 caracteres', () async {
    final invalidReport = ReportEntity(
      id: 'rep-1',
      reportNumber: '#0012',
      citizenId: 'user-1',
      citizenName: 'Carlos Gómez',
      categoryId: 'waste_accumulation',
      categoryName: 'Acumulación de basura',
      categoryIcon: 'delete_outline_rounded',
      description: 'Hola',
      priority: ReportPriority.medium,
      status: ReportStatus.pending,
      latitude: -12.046,
      longitude: -77.042,
      address: 'Av. Las Palmeras 412',
      imageUrls: const [],
      createdAt: DateTime.now(),
    );

    final result = await useCase(report: invalidReport);

    expect(result.isFailure, true);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(result.failureOrNull?.message, contains('al menos 5 caracteres'));
  });

  test('debe retornar ValidationFailure si la dirección está vacía', () async {
    final invalidReport = ReportEntity(
      id: 'rep-1',
      reportNumber: '#0012',
      citizenId: 'user-1',
      citizenName: 'Carlos Gómez',
      categoryId: 'waste_accumulation',
      categoryName: 'Acumulación de basura',
      categoryIcon: 'delete_outline_rounded',
      description: 'Bolsas acumuladas en la vereda.',
      priority: ReportPriority.medium,
      status: ReportStatus.pending,
      latitude: -12.046,
      longitude: -77.042,
      address: '   ',
      imageUrls: const [],
      createdAt: DateTime.now(),
    );

    final result = await useCase(report: invalidReport);

    expect(result.isFailure, true);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(result.failureOrNull?.message, contains('dirección'));
  });

  test('debe retornar Success y guardar el reporte cuando todos los campos son válidos', () async {
    final result = await useCase(report: validReport);

    expect(result.isSuccess, true);
    expect(result.dataOrNull?.reportNumber, '#0012');
    expect(fakeRepository.lastCreatedReport?.id, 'rep-1');
  });
}
