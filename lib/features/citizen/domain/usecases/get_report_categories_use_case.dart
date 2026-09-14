import '../../../../core/utils/result.dart';
import '../entities/report_category_entity.dart';
import '../repositories/report_repository.dart';

/// Caso de uso para obtener las categorías de reportes.
///
/// Ubicación: `lib/features/citizen/domain/usecases/get_report_categories_use_case.dart`
/// Capa: Domain (Use Cases)
class GetReportCategoriesUseCase {
  final ReportRepository _repository;

  const GetReportCategoriesUseCase(this._repository);

  Future<Result<List<ReportCategoryEntity>>> call() {
    return _repository.getCategories();
  }
}
