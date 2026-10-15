import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/citizen/presentation/views/citizen_profile_screen.dart';

class MockCitizenAuthViewModel extends AuthViewModel {
  final UserEntity? testUser;
  bool logoutCalled = false;
  bool resetEmailCalled = false;

  MockCitizenAuthViewModel(this.testUser);

  @override
  AuthState build() {
    return AuthState(
      user: testUser,
      isInitialized: true,
    );
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = const AuthState(isInitialized: true, user: null);
  }

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    resetEmailCalled = true;
    return true;
  }
}

final testCitizenUser = UserEntity(
  id: 'cit-101',
  name: 'Alejandro Rabanal',
  email: 'alejandro@gmail.com',
  role: UserRole.citizen,
  phoneNumber: '+51 987 654 321',
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  testWidgets('Renderiza CitizenProfileScreen con diseño fiel al mockup y sin opción de idioma',
      (tester) async {
    final mockAuth = MockCitizenAuthViewModel(testCitizenUser);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => mockAuth),
        ],
        child: const MaterialApp(
          home: CitizenProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Título de pantalla centrado
    expect(find.text('Mi perfil'), findsOneWidget);

    // 2. Avatar e Información del usuario
    expect(find.text('Alejandro Rabanal'), findsOneWidget);
    expect(find.text('alejandro@gmail.com'), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsWidgets);

    // 3. Tarjeta de Opciones requeridas
    expect(find.text('Mis datos'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.text('Notificaciones'), findsOneWidget);
    expect(find.text('Acerca de EcoRoute'), findsOneWidget);

    // 4. Verificación estricta: NO debe incluir la opción de idioma
    expect(find.text('Idioma'), findsNothing);
    expect(find.text('Español'), findsNothing);

    // 5. Opción destacada en rojo: Cerrar sesión
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);

    // 6. Barra de navegación inferior
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Reportar'), findsOneWidget);
    expect(find.text('Mis reportes'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('Abre modal de Mis datos personales al presionar la opción', (tester) async {
    final mockAuth = MockCitizenAuthViewModel(testCitizenUser);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => mockAuth),
        ],
        child: const MaterialApp(
          home: CitizenProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap en 'Mis datos'
    await tester.tap(find.text('Mis datos'));
    await tester.pumpAndSettle();

    // Verifica que se abra el bottom sheet con los datos
    expect(find.text('Mis datos personales'), findsOneWidget);
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Rol en la plataforma'), findsOneWidget);
    expect(find.text('Ciudadano Activo'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);

    // Cierra el modal
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('Mis datos personales'), findsNothing);
  });

  testWidgets('Abre modal de Notificaciones con toggles interactivos', (tester) async {
    final mockAuth = MockCitizenAuthViewModel(testCitizenUser);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => mockAuth),
        ],
        child: const MaterialApp(
          home: CitizenProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap en 'Notificaciones'
    await tester.tap(find.text('Notificaciones'));
    await tester.pumpAndSettle();

    expect(find.text('Preferencias de Notificaciones'), findsOneWidget);
    expect(find.text('Actualizaciones de reportes'), findsOneWidget);
    expect(find.text('Camión recolector cerca'), findsOneWidget);
    expect(find.text('Campañas y noticias ambientales'), findsOneWidget);
    expect(find.text('Guardar preferencias'), findsOneWidget);

    await tester.tap(find.text('Guardar preferencias'));
    await tester.pumpAndSettle();

    expect(find.text('Preferencias de Notificaciones'), findsNothing);
  });

  testWidgets('Muestra diálogo de confirmación antes de cerrar sesión', (tester) async {
    final mockAuth = MockCitizenAuthViewModel(testCitizenUser);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => mockAuth),
        ],
        child: const MaterialApp(
          home: CitizenProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap en 'Cerrar sesión'
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    // Verifica diálogo
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    expect(find.text('¿Estás seguro de que deseas salir de tu cuenta de EcoRoute?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    // Tap en Cerrar sesión del diálogo
    final confirmBtn = find.widgetWithText(ElevatedButton, 'Cerrar sesión');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(mockAuth.logoutCalled, isTrue);
  });
}
