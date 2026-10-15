import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/services/location_service.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_category_entity.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/citizen/domain/repositories/report_repository.dart';
import 'package:ecoroute/features/citizen/presentation/viewmodels/create_report_viewmodel.dart';
import 'package:ecoroute/features/citizen/presentation/views/create_report_wizard_screen.dart';

class MockWizardLocationService implements LocationService {
  @override
  Future<LocationDataResult> getCurrentPosition() async {
    return const LocationDataResult(
      latitude: -12.046374,
      longitude: -77.042793,
      address: 'Av. Las Palmeras 412, Centro',
    );
  }

  @override
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    return 'Av. Las Palmeras 412, Centro';
  }

  @override
  Future<LocationDataResult?> getCoordinatesFromAddress(String address) async {
    return const LocationDataResult(
      latitude: -12.046374,
      longitude: -77.042793,
      address: 'Av. Las Palmeras 412, Centro',
    );
  }
}

class MockWizardReportRepository implements ReportRepository {
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
}

void main() {
  testWidgets('Flujo completo del Wizard: Selecciona categoría, foto y ubicación interactiva con PIN', (WidgetTester tester) async {
    // Configurar un tamaño de pantalla realista para dispositivos móviles
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockLocation = MockWizardLocationService();
    final mockRepo = MockWizardReportRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(mockLocation),
          reportRepositoryProvider.overrideWithValue(mockRepo),
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
    expect(find.text('Agrega una fotografía'), findsOneWidget);
    expect(find.text('Tomar foto'), findsOneWidget);
    expect(find.text('Elegir de la galería'), findsOneWidget);

    // 5. Pulsamos en 'Siguiente' para avanzar al Paso 3 (Ubicación)
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    // 6. Verificamos elementos del Paso 3: Selección de ubicación
    expect(find.text('Selecciona la ubicación'), findsOneWidget);
    expect(find.text('Buscar o ingresar dirección...'), findsOneWidget);
    expect(find.text('Punto del incidente'), findsOneWidget);
    expect(find.text('Usar mi ubicación actual'), findsOneWidget);
    expect(find.text('Referencia adicional (opcional)'), findsOneWidget);

    // 7. Pulsamos en 'Usar mi ubicación actual' y verificamos actualización
    await tester.tap(find.text('Usar mi ubicación actual'));
    await tester.pumpAndSettle();

    // 8. Verificamos que el botón de Siguiente permite avanzar al Paso 4
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    // 9. Verificamos que avanzó al Paso 4 (Completa la información)
    expect(find.text('Completa la información'), findsOneWidget);
    expect(find.text('Descripción'), findsOneWidget);
  });

  testWidgets('Paso 3 de ubicación: Permite buscar dirección y reubicar el PIN en el mapa', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockLocation = MockWizardLocationService();
    final mockRepo = MockWizardReportRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(mockLocation),
          reportRepositoryProvider.overrideWithValue(mockRepo),
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
    await tester.tap(find.text('Siguiente')); // Paso 2 -> 3
    await tester.pumpAndSettle();

    // Verificamos controles del mapa interactivo
    expect(find.text('Toca o arrastra el PIN al lugar exacto'), findsOneWidget);
    expect(find.text('Punto del incidente'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_rounded), findsWidgets);
    expect(find.byTooltip('Acercar mapa'), findsOneWidget);
    expect(find.byTooltip('Alejar mapa'), findsOneWidget);
    expect(find.byTooltip('Recentrar en el PIN'), findsOneWidget);

    // Escribir en el buscador de dirección
    final searchInput = find.byType(TextField).first;
    await tester.enterText(searchInput, 'Av. Las Palmeras 412, Centro');
    await tester.pumpAndSettle();

    // Presionar el icono de búsqueda
    await tester.tap(find.byTooltip('Buscar en el mapa'));
    await tester.pumpAndSettle();

    expect(find.text('Av. Las Palmeras 412, Centro'), findsOneWidget);
  });
}
