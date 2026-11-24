import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/geo_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/report_category_entity.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/usecases/create_report_use_case.dart';
import '../../domain/usecases/get_report_categories_use_case.dart';
import 'create_report_state.dart';

// --- Inyección de Dependencias con Riverpod ---

final reportRemoteDataSourceProvider = Provider<ReportRemoteDataSource>((ref) {
  return FirebaseReportRemoteDataSourceImpl();
});

final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>((ref) {
  return FirebaseCategoryRemoteDataSourceImpl();
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final remoteDataSource = ref.watch(reportRemoteDataSourceProvider);
  final categoryDataSource = ref.watch(categoryRemoteDataSourceProvider);

  return ReportRepositoryImpl(
    remoteDataSource: remoteDataSource,
    categoryDataSource: categoryDataSource,
  );
});

final getReportCategoriesUseCaseProvider = Provider<GetReportCategoriesUseCase>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return GetReportCategoriesUseCase(repository);
});

final createReportUseCaseProvider = Provider<CreateReportUseCase>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return CreateReportUseCase(repository);
});

final createReportViewModelProvider =
    NotifierProvider.autoDispose<CreateReportViewModel, CreateReportState>(
      CreateReportViewModel.new,
    );

// --- ViewModel (MVVM) ---

/// ViewModel para gestionar la interfaz y estado del Wizard de Creación de Reportes en 5 pasos.
///
/// Principio SRP: Responsabilidad exclusiva de gestionar el estado de la UI del Wizard.
/// Delega la geolocalización a [LocationService] y la captura multimedia a [MediaPickerService].
///
/// Ubicación: `lib/features/citizen/presentation/viewmodels/create_report_viewmodel.dart`
/// Capa: Presentation (ViewModel)
class CreateReportViewModel extends Notifier<CreateReportState> {
  late final GetReportCategoriesUseCase _getCategoriesUseCase;
  late final CreateReportUseCase _createReportUseCase;
  late final LocationService _locationService;
  late final MediaPickerService _mediaPickerService;
  int _locationRequest = 0;

  @override
  CreateReportState build() {
    _getCategoriesUseCase = ref.watch(getReportCategoriesUseCaseProvider);
    _createReportUseCase = ref.watch(createReportUseCaseProvider);
    _locationService = ref.watch(locationServiceProvider);
    _mediaPickerService = ref.watch(mediaPickerServiceProvider);

    Future.microtask(loadCategories);

    return const CreateReportState();
  }

  /// Carga el catálogo de categorías de incidentes
  Future<void> loadCategories() async {
    if (!ref.mounted) return;
    state = state.copyWith(isLoadingCategories: true, clearError: true);
    final result = await _getCategoriesUseCase();
    if (!ref.mounted) return;

    result.fold(
      onSuccess: (categories) {
        state = state.copyWith(
          categories: categories,
          isLoadingCategories: false,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          categories: ReportCategoryEntity.defaultCategories,
          isLoadingCategories: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  /// Selecciona una categoría (Paso 1)
  void selectCategory(ReportCategoryEntity category) {
    state = state.copyWith(
      selectedCategory: category,
      priority: ReportPriority.fromString(category.defaultPriority),
      clearError: true,
    );
  }

  /// Captura de imagen desde Cámara (Paso 2)
  Future<void> pickImageFromCamera() async {
    if (state.imagesCount >= CreateReportState.maxImages) {
      state = state.copyWith(
        errorMessage:
            'Has alcanzado el límite máximo de ${CreateReportState.maxImages} fotografías.',
      );
      return;
    }
    final result = await _mediaPickerService.pickImageFromCamera();
    if (!ref.mounted) return;
    _handleSingleMediaResult(result);
  }

  void _handleSingleMediaResult(MediaPickResult result) {
    if (result.hasImage) {
      final updatedFiles = List.of(state.imageFiles)..add(result.file!);
      final updatedBytes = List.of(state.imageBytesList)..add(result.bytes!);
      state = state.copyWith(
        imageFiles: updatedFiles,
        imageBytesList: updatedBytes,
        clearError: true,
      );
    } else if (result.errorMessage != null) {
      state = state.copyWith(errorMessage: result.errorMessage);
    }
  }

  /// Eliminar fotografía en un índice específico
  void removeImageAt(int index) {
    if (index >= 0 && index < state.imagesCount) {
      final updatedFiles = List.of(state.imageFiles)..removeAt(index);
      final updatedBytes = List.of(state.imageBytesList)..removeAt(index);
      state = state.copyWith(
        imageFiles: updatedFiles,
        imageBytesList: updatedBytes,
        clearError: true,
      );
    }
  }

  /// Eliminar todas las fotografías adjuntas
  void removeImage() {
    state = state.copyWith(clearImage: true);
  }

  /// Obtiene la posición actual para ubicar el incidente.
  Future<bool> getCurrentLocation() async {
    final request = ++_locationRequest;
    state = state.copyWith(isLocating: true, clearError: true);

    final result = await _locationService.getCurrentPosition();
    if (!ref.mounted || request != _locationRequest) return false;
    if (result.errorMessage != null || result.isPermissionDenied) {
      state = state.copyWith(
        isLocating: false,
        errorMessage:
            result.errorMessage ??
            'No pudimos usar tu ubicación. Marca el incidente en el mapa.',
      );
      return false;
    }

    if (!AppGeoConstants.isInsideCajamarca(result.latitude, result.longitude)) {
      state = state.copyWith(
        isLocating: false,
        errorMessage:
            'Tu ubicación está fuera del área de servicio. Marca el incidente en el mapa de Cajamarca.',
      );
      return false;
    }

    state = state.copyWith(
      reportPoint: LatLng(result.latitude, result.longitude),
      userLatitude: result.latitude,
      userLongitude: result.longitude,
      address: _addressForPoint(
        result.latitude,
        result.longitude,
        result.address,
      ),
      isLocating: false,
    );
    return true;
  }

  /// Ubica el incidente donde el ciudadano marca el mapa.
  Future<void> updateCoordinates(double lat, double lng) async {
    final request = ++_locationRequest;
    final isInside = AppGeoConstants.isInsideCajamarca(lat, lng);
    state = state.copyWith(
      reportPoint: LatLng(lat, lng),
      address: isInside ? describeLocationCoordinates(lat, lng) : '',
      isLocating: isInside,
      clearError: true,
    );
    if (!isInside) return;

    final address = await _locationService.getAddressFromCoordinates(lat, lng);
    if (!ref.mounted || request != _locationRequest) return;
    state = state.copyWith(
      address: _addressForPoint(lat, lng, address),
      isLocating: false,
    );
  }

  /// Busca una dirección por texto y ubica el pin en sus coordenadas.
  Future<bool> searchAndSetAddress(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;
    final request = ++_locationRequest;
    state = state.copyWith(isLocating: true, clearError: true);

    final result = await _locationService.getCoordinatesFromAddress(trimmed);
    if (!ref.mounted || request != _locationRequest) return false;
    if (result == null) {
      state = state.copyWith(
        isLocating: false,
        errorMessage:
            'No se encontró la dirección "$trimmed" en Cajamarca. Puedes marcar el punto en el mapa.',
      );
      return false;
    }
    if (!AppGeoConstants.isInsideCajamarca(result.latitude, result.longitude)) {
      state = state.copyWith(
        isLocating: false,
        errorMessage:
            'La dirección "$trimmed" se encuentra fuera del área de servicio de Cajamarca.',
      );
      return false;
    }

    state = state.copyWith(
      reportPoint: LatLng(result.latitude, result.longitude),
      address: _addressForPoint(
        result.latitude,
        result.longitude,
        result.address,
      ),
      isLocating: false,
    );
    return true;
  }

  String _addressForPoint(double lat, double lng, String? address) {
    final resolved = address?.trim();
    return resolved == null || resolved.isEmpty
        ? describeLocationCoordinates(lat, lng)
        : resolved;
  }

  void setReference(String reference) {
    state = state.copyWith(reference: reference);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  void setPriority(ReportPriority priority) {
    state = state.copyWith(priority: priority);
  }

  /// Avanzar al siguiente paso del Wizard
  void nextStep() {
    if (state.currentStep == 1 && !state.canAdvanceFromStep1) {
      state = state.copyWith(
        errorMessage: 'Por favor, selecciona un tipo de problema antes de continuar.',
      );
      return;
    }

    if (state.currentStep == 2 && !state.canAdvanceFromStep2) {
      state = state.copyWith(
        errorMessage: 'Debes tomar al menos una fotografía instantánea para evidenciar el reporte.',
      );
      return;
    }

    if (state.currentStep == 3 && !state.canAdvanceFromStep3) {
      state = state.copyWith(
        errorMessage:
            'Usa tu ubicación actual o marca el incidente dentro del área de Cajamarca.',
      );
      return;
    }

    if (state.currentStep == 4) {
      submitReport();
      return;
    }

    if (state.currentStep < 5) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
      );
    }
  }

  /// Retroceder un paso en el Wizard
  void prevStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearError: true,
      );
    }
  }

  /// Navegar directamente a un paso específico
  void goToStep(int step) {
    if (step >= 1 && step <= 5) {
      state = state.copyWith(currentStep: step, clearError: true);
    }
  }

  /// Genera un código de reporte aleatorio y no repetible para rastreo único
  String _generateReportNumber() {
    final randomPart = 100000 + Random().nextInt(900000);
    return '#$randomPart';
  }

  /// Enviar y registrar el reporte (Paso 4 -> Paso 5)
  Future<bool> submitReport() async {
    if (state.isSubmitting) return false;
    final point = state.reportPoint;
    if (point == null || !state.canAdvanceFromStep3) {
      state = state.copyWith(
        errorMessage:
            'Selecciona la ubicación del incidente dentro del área de Cajamarca.',
      );
      return false;
    }
    if (!state.canAdvanceFromStep4) {
      state = state.copyWith(
        errorMessage:
            'Por favor ingrese una descripción de al menos 5 caracteres.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    final authState = ref.read(authViewModelProvider);
    final user = authState.user;

    final reportId = const Uuid().v4();
    final reportNumber = _generateReportNumber();

    final report = ReportEntity(
      id: reportId,
      reportNumber: reportNumber,
      citizenId: user?.id ?? 'guest_user',
      citizenName: user?.name ?? 'Ciudadano EcoRoute',
      citizenPhone: user?.phoneNumber,
      categoryId: state.selectedCategory?.id ?? 'other_issue',
      categoryName: state.selectedCategory?.name ?? 'Incidencia Ambiental',
      categoryIcon: state.selectedCategory?.icon ?? 'warning_amber_rounded',
      description: state.description.trim(),
      priority: state.priority,
      status: ReportStatus.pending,
      latitude: point.latitude,
      longitude: point.longitude,
      address: state.address.trim(),
      reference: state.reference.trim().isNotEmpty
          ? state.reference.trim()
          : null,
      imageUrls: const [],
      createdAt: DateTime.now(),
    );

    final result = await _createReportUseCase(
      report: report,
      imageBytes: state.imageBytes,
      multipleImageBytes: state.imageBytesList,
    );
    if (!ref.mounted) return false;

    return result.fold(
      onSuccess: (savedReport) {
        state = state.copyWith(
          isSubmitting: false,
          createdReportNumber: savedReport.reportNumber,
          currentStep: 5,
        );
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: switch (failure) {
            ValidationFailure() => failure.message,
            _ when failure.code == 'unauthenticated' =>
              'Tu sesión venció. Vuelve a iniciar sesión para enviar el reporte.',
            _ when failure.code == 'unavailable' || failure.code == 'deadline-exceeded' =>
              'No pudimos conectarnos para enviar tu reporte. Revisa tu conexión e inténtalo de nuevo.',
            _ => 'No pudimos enviar tu reporte en este momento. Inténtalo más tarde.',
          },
        );
        return false;
      },
    );
  }

  /// Reinicia el formulario para crear un nuevo reporte
  void resetForm() {
    _locationRequest++;
    state = const CreateReportState();
    loadCategories();
  }
}
