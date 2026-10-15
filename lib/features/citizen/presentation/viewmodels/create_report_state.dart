import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/report_category_entity.dart';
import '../../domain/entities/report_entity.dart';

/// Estado inmutable del Wizard de creación de reportes ciudadanos.
///
/// Ubicación: `lib/features/citizen/presentation/viewmodels/create_report_state.dart`
/// Capa: Presentation (ViewModels)
class CreateReportState {
  /// Paso actual del flujo (1: Categoría, 2: Foto, 3: Ubicación, 4: Detalles, 5: Éxito)
  final int currentStep;
  final List<ReportCategoryEntity> categories;
  final ReportCategoryEntity? selectedCategory;
  final XFile? imageFile;
  final Uint8List? imageBytes;
  final double latitude;
  final double longitude;
  final double? userLatitude;
  final double? userLongitude;
  final String address;
  final String reference;
  final String description;
  final ReportPriority priority;
  final bool isLoadingCategories;
  final bool isLocating;
  final bool isSubmitting;
  final String? createdReportNumber;
  final String? errorMessage;

  const CreateReportState({
    this.currentStep = 1,
    this.categories = const [],
    this.selectedCategory,
    this.imageFile,
    this.imageBytes,
    this.latitude = -12.046374, // Coordenadas por defecto de ejemplo (Lima Centro)
    this.longitude = -77.042793,
    this.userLatitude,
    this.userLongitude,
    this.address = 'Cargando ubicación...',
    this.reference = '',
    this.description = '',
    this.priority = ReportPriority.medium,
    this.isLoadingCategories = false,
    this.isLocating = false,
    this.isSubmitting = false,
    this.createdReportNumber,
    this.errorMessage,
  });

  bool get hasUserLocation => userLatitude != null && userLongitude != null;

  bool get canAdvanceFromStep1 => selectedCategory != null;
  bool get canAdvanceFromStep2 => true; // La fotografía es altamente recomendada pero no bloqueante
  bool get canAdvanceFromStep3 => address.trim().isNotEmpty;
  bool get canAdvanceFromStep4 => description.trim().length >= 5;

  CreateReportState copyWith({
    int? currentStep,
    List<ReportCategoryEntity>? categories,
    ReportCategoryEntity? selectedCategory,
    bool clearSelectedCategory = false,
    XFile? imageFile,
    bool clearImage = false,
    Uint8List? imageBytes,
    double? latitude,
    double? longitude,
    double? userLatitude,
    double? userLongitude,
    String? address,
    String? reference,
    String? description,
    ReportPriority? priority,
    bool? isLoadingCategories,
    bool? isLocating,
    bool? isSubmitting,
    String? createdReportNumber,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateReportState(
      currentStep: currentStep ?? this.currentStep,
      categories: categories ?? this.categories,
      selectedCategory: clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      imageFile: clearImage ? null : (imageFile ?? this.imageFile),
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      address: address ?? this.address,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isLocating: isLocating ?? this.isLocating,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdReportNumber: createdReportNumber ?? this.createdReportNumber,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
