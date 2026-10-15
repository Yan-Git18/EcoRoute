import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/geo_constants.dart';
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
  final List<XFile> imageFiles;
  final List<Uint8List> imageBytesList;
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
    this.imageFiles = const [],
    this.imageBytesList = const [],
    XFile? imageFile,
    Uint8List? imageBytes,
    this.latitude = AppGeoConstants.cajamarcaCenterLat, // Centro de Cajamarca, Perú
    this.longitude = AppGeoConstants.cajamarcaCenterLng,
    this.userLatitude,
    this.userLongitude,
    this.address = AppGeoConstants.defaultAddress,
    this.reference = '',
    this.description = '',
    this.priority = ReportPriority.medium,
    this.isLoadingCategories = false,
    this.isLocating = false,
    this.isSubmitting = false,
    this.createdReportNumber,
    this.errorMessage,
  });

  /// Getters de compatibilidad y control de galería múltiple
  XFile? get imageFile => imageFiles.isNotEmpty ? imageFiles.first : null;
  Uint8List? get imageBytes => imageBytesList.isNotEmpty ? imageBytesList.first : null;
  bool get hasImage => imageBytesList.isNotEmpty;
  int get imagesCount => imageBytesList.length;
  static const int maxImages = 4;
  bool get canAddMoreImages => imagesCount < maxImages;

  bool get hasUserLocation => userLatitude != null && userLongitude != null;
  bool get isLocationInsideCajamarca => AppGeoConstants.isInsideCajamarca(latitude, longitude);

  bool get canAdvanceFromStep1 => selectedCategory != null;
  bool get canAdvanceFromStep2 => true; // La fotografía es altamente recomendada pero no bloqueante
  bool get canAdvanceFromStep3 => address.trim().isNotEmpty && isLocationInsideCajamarca;
  bool get canAdvanceFromStep4 => description.trim().length >= 5;

  CreateReportState copyWith({
    int? currentStep,
    List<ReportCategoryEntity>? categories,
    ReportCategoryEntity? selectedCategory,
    bool clearSelectedCategory = false,
    List<XFile>? imageFiles,
    List<Uint8List>? imageBytesList,
    XFile? imageFile,
    Uint8List? imageBytes,
    bool clearImage = false,
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
    List<XFile> nextFiles = imageFiles ?? this.imageFiles;
    List<Uint8List> nextBytes = imageBytesList ?? this.imageBytesList;

    if (clearImage) {
      nextFiles = const [];
      nextBytes = const [];
    } else if (imageFile != null && imageBytes != null) {
      nextFiles = [imageFile];
      nextBytes = [imageBytes];
    }

    return CreateReportState(
      currentStep: currentStep ?? this.currentStep,
      categories: categories ?? this.categories,
      selectedCategory: clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      imageFiles: nextFiles,
      imageBytesList: nextBytes,
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
