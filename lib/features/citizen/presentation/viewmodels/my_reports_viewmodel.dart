import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/cancel_report_use_case.dart';
import '../../domain/usecases/get_my_reports_use_case.dart';
import '../../domain/usecases/get_report_by_id_use_case.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import 'create_report_viewmodel.dart';
import 'my_reports_state.dart';

// --- Inyección de Dependencias con Riverpod ---

final getMyReportsUseCaseProvider = Provider<GetMyReportsUseCase>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return GetMyReportsUseCase(repository);
});

final getReportByIdUseCaseProvider = Provider<GetReportByIdUseCase>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return GetReportByIdUseCase(repository);
});

final cancelReportUseCaseProvider = Provider<CancelReportUseCase>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return CancelReportUseCase(repository);
});

final myReportsViewModelProvider =
    NotifierProvider<MyReportsViewModel, MyReportsState>(MyReportsViewModel.new);

// --- ViewModel (MVVM) ---

/// ViewModel para gestionar el listado y filtrado de "Mis reportes".
///
/// Ubicación: `lib/features/citizen/presentation/viewmodels/my_reports_viewmodel.dart`
/// Capa: Presentation (ViewModel)
class MyReportsViewModel extends Notifier<MyReportsState> {
  late final GetMyReportsUseCase _getMyReportsUseCase;

  @override
  MyReportsState build() {
    _getMyReportsUseCase = ref.watch(getMyReportsUseCaseProvider);

    // Cargar reportes del usuario al instanciar
    Future.microtask(() => loadReports());

    return const MyReportsState(isLoading: true);
  }

  /// Carga la lista de reportes asociados al ciudadano logueado
  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final authState = ref.read(authViewModelProvider);
    final citizenId = authState.user?.id;

    if (citizenId == null || citizenId.isEmpty) {
      // Si no hay sesión activa, no se muestran reportes
      state = state.copyWith(reports: const [], isLoading: false);
      return;
    }

    final result = await _getMyReportsUseCase(citizenId);

    result.fold(
      onSuccess: (reports) {
        state = state.copyWith(
          reports: reports,
          isLoading: false,
        );
      },
      onFailure: (failure) {
        // En caso de error de red o permisos, mantenemos la lista limpia sin datos falsos
        state = state.copyWith(
          reports: const [],
          isLoading: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  /// Cambia el filtro de visualización (Todos, Pendientes, En proceso, Resueltos)
  void setFilter(ReportFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  /// Recarga manual (Pull-to-refresh)
  Future<void> refresh() async {
    await loadReports();
  }
}
