import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ecoroute/core/errors/failures.dart';
import 'package:ecoroute/core/services/location_service.dart';
import 'package:ecoroute/core/services/media_picker_service.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_category_entity.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/citizen/domain/repositories/report_repository.dart';
import 'package:ecoroute/features/citizen/presentation/viewmodels/create_report_viewmodel.dart';
import 'package:ecoroute/core/constants/geo_constants.dart';
import 'package:ecoroute/features/citizen/presentation/views/create_report_wizard_screen.dart';

final _kTestPngBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

class MockWizardMediaPickerService implements MediaPickerService {
  @override
  Future<MediaPickResult> pickImageFromCamera({
    int quality = 70,
    double maxWidth = 800,
    double maxHeight = 800,
  }) async {
    return MediaPickResult(
      file: XFile('test_photo.png'),
      bytes: _kTestPngBytes,
    );
  }

  @override
  Future<MediaPickResult> pickImageFromGallery({
    int quality = 70,
    double maxWidth = 800,
    double maxHeight = 800,
  }) async {
    return const MediaPickResult();
  }

  @override
  Future<List<MediaPickResult>> pickMultipleImagesFromGallery({
    int quality = 70,
    double maxWidth = 800,
    double maxHeight = 800,
    int? limit,
  }) async {
    return const [];
  }
}

class MockWizardLocationService implements LocationService {
  LocationDataResult gpsResult = const LocationDataResult(
    latitude: -7.147,
    longitude: -78.505,
    address: 'Av. del Maestro',
  );
  Completer<LocationDataResult>? pendingGps;
  int gpsRequests = 0;

  @override
  Future<LocationDataResult> getCurrentPosition() async {
    gpsRequests++;
    return pendingGps?.future ?? gpsResult;
  }

  @override
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    return describeLocationCoordinates(lat, lng);
  }

  @override
  Future<LocationDataResult?> getCoordinatesFromAddress(String address) async {
    return const LocationDataResult(
      latitude: -7.155,
      longitude: -78.520,
      address: 'Jr. del Batán',
    );
  }
}

class MockWizardReportRepository implements ReportRepository {
  bool failSave = false;
  ReportEntity? savedReport;

  @override
  Future<Result<List<ReportCategoryEntity>>> getCategories() async {
    return const Success(ReportCategoryEntity.defaultCategories);
  }

  @override
  Future<Result<ReportEntity>> createReport({
    required ReportEntity report,
    List<int>? imageBytes,
    List<List<int>>? multipleImageBytes,
  }) async {
    if (failSave) {
      return const FailureResult(
        ServerFailure(
          message: 'Permisos insuficientes en Firestore.',
          code: 'permission-denied',
        ),
      );
    }
    savedReport = report;
    return Success(report);
  }

  @override
  Future<Result<List<ReportEntity>>> getMyReports(String citizenId) async {
    return const Success([]);
  }

  @override
  Future<Result<ReportEntity>> getReportById(String reportId) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<ReportEntity>>> getAllReports() async {
    return const Success([]);
  }

  @override
  Future<Result<ReportEntity>> cancelReport({required String reportId, String? reason}) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('Flujo completo del Wizard: Selecciona categoría, foto y ubicación interactiva con PIN', (WidgetTester tester) async {
    // Configurar un tamaño de pantalla realista para dispositivos móviles
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockLocation = MockWizardLocationService();
    final mockRepo = MockWizardReportRepository();
    final mockMedia = MockWizardMediaPickerService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(mockLocation),
          reportRepositoryProvider.overrideWithValue(mockRepo),
          mediaPickerServiceProvider.overrideWithValue(mockMedia),
        ],
        child: const MaterialApp(
          home: CreateReportWizardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verificamos elementos del Paso 1
    expect(find.text('Crear reporte'), findsOneWidget);
    expect(find.text('¿Qué problema encontraste?'), findsOneWidget);
    expect(find.text('Acumulación de basura'), findsOneWidget);
    expect(find.text('Contenedor lleno'), findsOneWidget);
    expect(find.text('Residuos en vía pública'), findsOneWidget);

    // 2. Seleccionamos la categoría 'Acumulación de basura'
    await tester.tap(find.text('Acumulación de basura'));
    await tester.pumpAndSettle();

    // 3. Pulsamos en 'Siguiente'
    expect(find.text('Siguiente'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    // 4. Verificamos que avanzó al Paso 2 (Fotografía)
    expect(find.textContaining('Agrega una fotografía'), findsOneWidget);
    expect(find.text('Tomar foto instantánea'), findsOneWidget);
    expect(find.text('0 / 4 fotos'), findsOneWidget);

    // Intentamos avanzar sin foto: debe mantenerse en el Paso 2
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Agrega una fotografía'), findsOneWidget);

    // Tomamos una foto instantánea con la cámara
    await tester.tap(find.text('Tomar foto instantánea'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 4 fotos'), findsOneWidget);

    // 5. Pulsamos en 'Siguiente' para avanzar al Paso 3 (Ubicación)
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    // 6. Verificamos elementos del Paso 3: Selección de ubicación
    expect(find.text('Selecciona la ubicación'), findsOneWidget);
    expect(find.text('Buscar dirección en Cajamarca'), findsOneWidget);
    expect(find.text('Punto del incidente'), findsNothing);
    expect(find.text('Usar mi ubicación actual'), findsOneWidget);
    expect(find.text('Referencia adicional (opcional)'), findsOneWidget);
    expect(mockLocation.gpsRequests, 0);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Confirmar ubicación'),
          )
          .onPressed,
      isNull,
    );

    // 7. Pulsamos en 'Usar mi ubicación actual' y verificamos actualización
    await tester.tap(find.text('Usar mi ubicación actual'));
    await tester.pumpAndSettle();
    expect(find.text('Punto del incidente'), findsOneWidget);
    expect(find.text('Av. del Maestro'), findsOneWidget);

    // 8. Verificamos que el botón de Siguiente permite avanzar al Paso 4
    await tester.tap(find.text('Confirmar ubicación'));
    await tester.pumpAndSettle();

    // 9. Verificamos que avanzó al Paso 4 (Completa la información)
    expect(find.text('Completa la información'), findsOneWidget);
    expect(find.text('Descripción'), findsOneWidget);

    const description = 'Residuos acumulados en la vía';
    await tester.enterText(find.byType(TextField).first, description);
    await tester.pumpAndSettle();
    mockRepo.failSave = true;
    await tester.tap(find.text('Enviar reporte'));
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos enviar tu reporte en este momento. Inténtalo más tarde.'),
      findsOneWidget,
    );
    expect(find.textContaining('Firestore'), findsNothing);
    expect(find.text('Adjunta (1 foto)'), findsOneWidget);
    expect(find.text(description), findsOneWidget);
    expect(find.text('Completa la información'), findsOneWidget);

    mockRepo.failSave = false;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar reporte'));
    await tester.pumpAndSettle();
    expect(find.text('¡Reporte enviado!'), findsOneWidget);
    expect(mockRepo.savedReport?.latitude, -7.147);
    expect(mockRepo.savedReport?.longitude, -78.505);
  });

  testWidgets('El GPS denegado o fuera de cobertura requiere marcar o buscar un punto', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockLocation = MockWizardLocationService();
    final mockRepo = MockWizardReportRepository();
    final mockMedia = MockWizardMediaPickerService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(mockLocation),
          reportRepositoryProvider.overrideWithValue(mockRepo),
          mediaPickerServiceProvider.overrideWithValue(mockMedia),
        ],
        child: const MaterialApp(
          home: CreateReportWizardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Avanzar al paso 3
    await tester.tap(find.text('Acumulación de basura'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente')); // Paso 1 -> 2
    await tester.pumpAndSettle();

    // Tomar fotografía obligatoria en el Paso 2
    await tester.tap(find.text('Tomar foto instantánea'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Siguiente')); // Paso 2 -> 3
    await tester.pumpAndSettle();

    // Verificamos controles del mapa interactivo
    final confirmButton = find.widgetWithText(
      ElevatedButton,
      'Confirmar ubicación',
    );
    expect(find.text('Cajamarca • Toca para marcar'), findsOneWidget);
    expect(find.text('Punto del incidente'), findsNothing);
    expect(find.byTooltip('Acercar mapa'), findsOneWidget);
    expect(find.byTooltip('Alejar mapa'), findsOneWidget);
    expect(find.byTooltip('Recentrar en el PIN'), findsNothing);

    mockLocation.gpsResult = const LocationDataResult(
      latitude: AppGeoConstants.cajamarcaCenterLat,
      longitude: AppGeoConstants.cajamarcaCenterLng,
      address: AppGeoConstants.defaultAddress,
      isPermissionDenied: true,
    );
    await tester.tap(find.text('Usar mi ubicación actual'));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);
    expect(find.text('Punto del incidente'), findsNothing);

    mockLocation.gpsResult = const LocationDataResult(
      latitude: -12.046,
      longitude: -77.042,
    );
    await tester.tap(find.text('Usar mi ubicación actual'));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);
    expect(find.text('Punto del incidente'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Batán');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);
    await tester.tap(find.byTooltip('Buscar en el mapa'));
    await tester.pumpAndSettle();
    expect(find.text('Jr. del Batán'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('report-location-map')));
    await tester.pumpAndSettle();
    expect(find.text('Jr. del Batán'), findsNothing);
    expect(find.text('Punto del incidente'), findsOneWidget);
    expect(find.byTooltip('Recentrar en el PIN'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNotNull);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
    expect(find.text('Completa la información'), findsOneWidget);
  });

  test(
    'El GPS tardío no reemplaza el punto marcado y un nuevo reporte empieza sin punto',
    () async {
      final gps = Completer<LocationDataResult>();
      final location = MockWizardLocationService()..pendingGps = gps;
      final repository = MockWizardReportRepository();
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(location),
          reportRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      container.listen(createReportViewModelProvider, (_, _) {});
      final viewModel = container.read(createReportViewModelProvider.notifier);

      viewModel.setDescription('Residuos acumulados en la vía');
      expect(await viewModel.submitReport(), isFalse);
      expect(repository.savedReport, isNull);

      final gpsRequest = viewModel.getCurrentLocation();
      await viewModel.updateCoordinates(-7.151, -78.527);
      gps.complete(location.gpsResult);

      expect(await gpsRequest, isFalse);
      expect(
        container.read(createReportViewModelProvider).reportPoint?.latitude,
        -7.151,
      );
      expect(
        container.read(createReportViewModelProvider).canAdvanceFromStep3,
        isTrue,
      );

      await viewModel.updateCoordinates(-7.165, -78.529);
      expect(
        container.read(createReportViewModelProvider).canAdvanceFromStep3,
        isFalse,
      );
      viewModel.resetForm();
      expect(container.read(createReportViewModelProvider).reportPoint, isNull);
      expect(location.gpsRequests, 1);
      await Future<void>.delayed(Duration.zero);
    },
  );
}
