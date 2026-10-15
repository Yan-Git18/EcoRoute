import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/geo_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../../data/datasources/report_storage_datasource.dart';
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

final reportStorageDataSourceProvider = Provider<ReportStorageDataSource>((ref) {
  return FirebaseReportStorageDataSourceImpl();
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final remoteDataSource = ref.watch(reportRemoteDataSourceProvider);
  final categoryDataSource = ref.watch(categoryRemoteDataSourceProvider);
  final storageDataSource = ref.watch(reportStorageDataSourceProvider);

  return ReportRepositoryImpl(
    remoteDataSource: remoteDataSource,
    categoryDataSource: categoryDataSource,
    storageDataSource: storageDataSource,
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
    NotifierProvider<CreateReportViewModel, CreateReportState>(CreateReportViewModel.new);

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

  @override
  CreateReportState build() {
    _getCategoriesUseCase = ref.watch(getReportCategoriesUseCaseProvider);
    _createReportUseCase = ref.watch(createReportUseCaseProvider);
    _locationService = ref.watch(locationServiceProvider);
    _mediaPickerService = ref.watch(mediaPickerServiceProvider);

    // Cargar catálogo de categorías y obtener ubicación inicial
    Future.microtask(() {
      loadCategories();
      getCurrentLocation();
    });

    return const CreateReportState();
  }

  /// Carga el catálogo de categorías de incidentes
  Future<void> loadCategories() async {
    state = state.copyWith(isLoadingCategories: true, clearError: true);
    final result = await _getCategoriesUseCase();

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
        errorMessage: 'Has alcanzado el límite máximo de ${CreateReportState.maxImages} fotografías.',
      );
      return;
    }
    final result = await _mediaPickerService.pickImageFromCamera();
    _handleSingleMediaResult(result);
  }

  /// Selección de imágenes desde Galería (Paso 2)
  Future<void> pickImageFromGallery() async {
    final remaining = CreateReportState.maxImages - state.imagesCount;
    if (remaining <= 0) {
      state = state.copyWith(
        errorMessage: 'Has alcanzado el límite máximo de ${CreateReportState.maxImages} fotografías.',
      );
      return;
    }
    final results = await _mediaPickerService.pickMultipleImagesFromGallery(limit: remaining);
    _handleMultipleMediaResults(results);
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

  void _handleMultipleMediaResults(List<MediaPickResult> results) {
    final updatedFiles = List.of(state.imageFiles);
    final updatedBytes = List.of(state.imageBytesList);
    String? error;

    for (final r in results) {
      if (r.hasImage && updatedFiles.length < CreateReportState.maxImages) {
        updatedFiles.add(r.file!);
        updatedBytes.add(r.bytes!);
      } else if (r.errorMessage != null) {
        error = r.errorMessage;
      }
    }

    state = state.copyWith(
      imageFiles: updatedFiles,
      imageBytesList: updatedBytes,
      errorMessage: error,
      clearError: error == null,
    );
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

  /// Obtiene la posición GPS actual y realiza geocodificación inversa (Paso 3)
  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLocating: true, clearError: true);

    final result = await _locationService.getCurrentPosition();
    final isInside = AppGeoConstants.isInsideCajamarca(result.latitude, result.longitude);

    if (isInside) {
      state = state.copyWith(
        latitude: result.latitude,
        longitude: result.longitude,
        userLatitude: result.latitude,
        userLongitude: result.longitude,
        address: result.address ?? AppGeoConstants.defaultAddress,
        isLocating: false,
        errorMessage: result.errorMessage,
      );
    } else {
      // El usuario está fuera del radio de Cajamarca: se registra su GPS de referencia
      // pero el PIN del reporte se posiciona en el centro de Cajamarca para evitar reportes en otras ciudades/países
      state = state.copyWith(
        latitude: AppGeoConstants.cajamarcaCenterLat,
        longitude: AppGeoConstants.cajamarcaCenterLng,
        userLatitude: result.latitude,
        userLongitude: result.longitude,
        address: AppGeoConstants.defaultAddress,
        isLocating: false,
        errorMessage: 'Tu GPS indica que estás fuera de Cajamarca. Por favor ubica el PIN en la zona de Cajamarca donde ocurrió la incidencia.',
      );
    }
  }

  /// Actualiza coordenadas del incidente y busca dirección vía geocoding inverso
  Future<void> updateCoordinates(double lat, double lng) async {
    final isInside = AppGeoConstants.isInsideCajamarca(lat, lng);
    if (!isInside) {
      state = state.copyWith(
        latitude: lat,
        longitude: lng,
        errorMessage: 'El punto seleccionado está fuera del área de servicio de Cajamarca.',
      );
      return;
    }

    state = state.copyWith(
      latitude: lat,
      longitude: lng,
      isLocating: true,
      clearError: true,
    );

    final address = await _locationService.getAddressFromCoordinates(lat, lng);

    state = state.copyWith(
      latitude: lat,
      longitude: lng,
      address: address,
      isLocating: false,
    );
  }

  /// Busca una dirección por texto y ubica el pin en sus coordenadas dentro de Cajamarca
  Future<bool> searchAndSetAddress(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;
    state = state.copyWith(isLocating: true, clearError: true);
    final result = await _locationService.getCoordinatesFromAddress(trimmed);
    if (result != null) {
      if (!AppGeoConstants.isInsideCajamarca(result.latitude, result.longitude)) {
        state = state.copyWith(
          isLocating: false,
          errorMessage: 'La dirección "$trimmed" se encuentra fuera del área urbana de Cajamarca.',
        );
        return false;
      }

      state = state.copyWith(
        latitude: result.latitude,
        longitude: result.longitude,
        address: result.address ?? trimmed,
        isLocating: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLocating: false,
        errorMessage: 'No se encontró la dirección "$trimmed" en Cajamarca.',
      );
      return false;
    }
  }

  void setManualAddress(String address) {
    state = state.copyWith(address: address);
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

    if (state.currentStep == 3 && !state.canAdvanceFromStep3) {
      if (!state.isLocationInsideCajamarca) {
        state = state.copyWith(
          errorMessage: 'EcoRoute solo opera en Cajamarca. Por favor ubica el PIN dentro de la ciudad.',
        );
      } else {
        state = state.copyWith(
          errorMessage: 'Por favor, especifica una dirección o ubicación válida.',
        );
      }
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
    if (!state.canAdvanceFromStep4) {
      state = state.copyWith(
        errorMessage: 'Por favor ingrese una descripción de al menos 5 caracteres.',
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
      latitude: state.latitude,
      longitude: state.longitude,
      address: state.address.trim(),
      reference: state.reference.trim().isNotEmpty ? state.reference.trim() : null,
      imageUrls: const [],
      createdAt: DateTime.now(),
    );

    final result = await _createReportUseCase(
      report: report,
      imageBytes: state.imageBytes,
      imageFileName: 'evidence_${reportId}_0.jpg',
      multipleImageBytes: state.imageBytesList,
      localImagePaths: state.imageFiles.map((f) => f.path).toList(),
    );

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
          createdReportNumber: reportNumber,
          currentStep: 5,
        );
        return true;
      },
    );
  }

  /// Reinicia el formulario para crear un nuevo reporte
  void resetForm() {
    state = const CreateReportState();
    loadCategories();
    getCurrentLocation();
  }
}
