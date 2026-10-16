import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/domain/entities/report_entity.dart';
import 'package:ecoroute/features/staff/domain/entities/staff_task_entity.dart';
import 'package:ecoroute/features/staff/domain/repositories/staff_repository.dart';
import 'package:ecoroute/features/staff/presentation/viewmodels/staff_home_viewmodel.dart';
import 'package:ecoroute/features/staff/presentation/widgets/staff_complete_task_sheet.dart';

class MockStaffAuthViewModel extends AuthViewModel {
  final UserEntity? testUser;
  MockStaffAuthViewModel(this.testUser);

  @override
  AuthState build() {
    return AuthState(
      user: testUser,
      isInitialized: true,
    );
  }
}

class MockStaffRepository implements StaffRepository {
  List<StaffTaskEntity> tasks = [];
  bool completeTaskCalled = false;

  @override
  Future<Result<List<StaffTaskEntity>>> getAssignedTasks(String staffId) async {
    return Success(tasks);
  }

  @override
  Future<Result<StaffTaskEntity>> getTaskById(String taskId) async {
    final match = tasks.firstWhere((t) => t.id == taskId);
    return Success(match);
  }

  @override
  Future<Result<StaffTaskEntity>> updateTaskStatus({
    required String taskId,
    required String staffId,
    required String staffName,
    required ReportStatus newStatus,
    String? notes,
    String? evidenceImageUrl,
  }) async {
    final match = tasks.firstWhere((t) => t.id == taskId);
    final updated = match.copyWith(status: newStatus);
    return Success(updated);
  }

  @override
  Future<Result<StaffTaskEntity>> completeTaskWithEvidence({
    required String taskId,
    required String staffId,
    required String staffName,
    required List<int> evidenceImageBytes,
    required String notes,
  }) async {
    completeTaskCalled = true;
    final match = tasks.firstWhere((t) => t.id == taskId);
    final updated = match.copyWith(
      status: ReportStatus.resolved,
      resolutionNotes: notes,
    );
    return Success(updated);
  }
}

final testStaff = UserEntity(
  id: 'staff-test-1',
  name: 'Carlos Mendoza',
  email: 'carlos@ecoroute.com',
  role: UserRole.staff,
  createdAt: DateTime(2025, 1, 1),
);

final sampleTask = StaffTaskEntity(
  id: 'task-951488',
  reportNumber: '#951488',
  citizenId: 'citizen-1',
  citizenName: 'Vecino Cajamarca',
  categoryName: 'Contenedor lleno',
  categoryIcon: 'delete_outline',
  description: 'Contenedor lleno en Jr. Del Comercio',
  priority: ReportPriority.medium,
  status: ReportStatus.inProgress,
  address: 'Jr. Del Comercio 620, Centro Histórico',
  latitude: -7.158,
  longitude: -78.518,
  reportImageUrls: const [],
  assignedAt: DateTime.now(),
);

void main() {
  testWidgets('Renderiza StaffCompleteTaskSheet exactamente segun el mockup',
      (tester) async {
    final mockRepo = MockStaffRepository();
    mockRepo.tasks = [sampleTask];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockStaffAuthViewModel(testStaff)),
          staffRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => StaffCompleteTaskSheet.show(context, sampleTask),
                child: const Text('Abrir Resolver'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Abrir el modal bottom sheet
    await tester.tap(find.text('Abrir Resolver'));
    await tester.pumpAndSettle();

    // 1. Cabecera con título, folio y badge 'En atención'
    expect(find.text('Resolver tarea'), findsOneWidget);
    expect(find.text('Incidencia #951488'), findsOneWidget);
    expect(find.text('En atención'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // 2. Sección Evidencia fotográfica
    expect(find.text('Evidencia fotográfica'), findsOneWidget);
    expect(find.text('*'), findsOneWidget);
    expect(find.text('Agrega una foto para validar la limpieza.'), findsOneWidget);

    // 3. Botones Tomar foto y Elegir de galería
    expect(find.text('Tomar foto'), findsOneWidget);
    expect(find.text('Elegir de galería'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);

    // 4. Sección Notas de limpieza
    expect(find.text('Notas de limpieza'), findsOneWidget);
    expect(find.text('Describe brevemente el trabajo realizado...'), findsOneWidget);
    expect(find.text('0/500'), findsOneWidget);

    // 5. Botón Finalizar limpieza
    expect(find.text('Finalizar limpieza'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // 6. Nota informativa al pie
    expect(find.text('La fotografía es obligatoria para continuar.'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });

  testWidgets('StaffCompleteTaskSheet valida que la foto sea obligatoria al pulsar Finalizar',
      (tester) async {
    final mockRepo = MockStaffRepository();
    mockRepo.tasks = [sampleTask];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => MockStaffAuthViewModel(testStaff)),
          staffRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => StaffCompleteTaskSheet.show(context, sampleTask),
                child: const Text('Abrir Resolver'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Abrir el modal bottom sheet
    await tester.tap(find.text('Abrir Resolver'));
    await tester.pumpAndSettle();

    // Pulsar 'Finalizar limpieza' sin haber tomado o seleccionado una foto
    await tester.tap(find.text('Finalizar limpieza'));
    await tester.pumpAndSettle();

    // Debe mostrar el mensaje de validación
    expect(
      find.text('Por favor tome o elija una fotografía para validar la limpieza.'),
      findsOneWidget,
    );
  });
}
