import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_state.dart';
import 'package:ecoroute/features/admin/presentation/viewmodels/admin_reports_viewmodel.dart';
import 'package:ecoroute/features/admin/presentation/views/admin_routes_screen.dart';
import 'package:ecoroute/features/routes/domain/collection_route.dart';
import 'package:ecoroute/features/routes/domain/collection_route_repository.dart';
import 'package:ecoroute/features/routes/presentation/collection_route_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Muestra el acceso denegado y recarga las tres pestañas', (
    tester,
  ) async {
    var reads = 0;
    final repository = _RoutesRepository(() {
      reads++;
      if (reads == 1) {
        return Stream.error(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );
      }
      return Stream.value(const []);
    });
    await tester.pumpWidget(_app(repository));
    await tester.pump();

    expect(
      find.textContaining('Firestore rechazó la consulta'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(reads, 1);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay rutas planificadas.'), findsOneWidget);
    await tester.tap(find.text('En curso'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ningún equipo está ejecutando una ruta.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(
      find.text('Aún no hay rutas finalizadas o canceladas.'),
      findsOneWidget,
    );
    expect(reads, 2);
  });

  testWidgets(
    'Termina la carga si Firestore no entrega una respuesta inicial',
    (tester) async {
      await tester.pumpWidget(
        _app(_RoutesRepository(() => Stream.multi((_) {}))),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 12));
      await tester.pump();
      expect(
        find.textContaining('Firestore no respondió a tiempo'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}

Widget _app(CollectionRouteRepository repository) => ProviderScope(
  overrides: [
    collectionRouteRepositoryProvider.overrideWithValue(repository),
    adminReportsViewModelProvider.overrideWith(_ReportsViewModel.new),
  ],
  child: const MaterialApp(home: AdminRoutesScreen()),
);

class _ReportsViewModel extends AdminReportsViewModel {
  @override
  AdminReportsState build() => const AdminReportsState();
}

class _RoutesRepository implements CollectionRouteRepository {
  const _RoutesRepository(this._watch);

  final Stream<List<CollectionRoute>> Function() _watch;

  @override
  Stream<List<CollectionRoute>> watchRoutes({String? crewId}) => _watch();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
