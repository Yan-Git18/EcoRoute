import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ecoroute/features/auth/data/models/user_dto.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/auth/presentation/views/login_screen.dart';
import 'package:ecoroute/features/auth/presentation/views/register_screen.dart';
import 'package:ecoroute/features/auth/presentation/views/welcome_screen.dart';

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<UserDto> signInWithEmail({required String email, required String password}) async {
    return UserDto(id: '1', name: 'Test', email: email, role: 'citizen', createdAt: DateTime.now());
  }

  @override
  Future<UserDto> signUpWithEmail({required String name, required String email, required String password, required String role, String? phoneNumber}) async {
    return UserDto(id: '1', name: name, email: email, role: role, createdAt: DateTime.now());
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserDto?> getCurrentUser() async => null;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Stream<UserDto?> authStateChanges() => Stream.value(null);
}

void main() {
  testWidgets('Renderiza WelcomeScreen con boton Comenzar y Ya tengo una cuenta', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    // Verifica que se muestre el lema oficial de EcoRoute en 2 líneas
    expect(find.text('Juntos por ciudades\nmás limpias'), findsOneWidget);
    // Verifica los botones principales
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.text('Ya tengo una cuenta'), findsOneWidget);
  });

  testWidgets('Renderiza LoginScreen con logo de EcoRoute y campos requeridos', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(FakeAuthRemoteDataSource()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verificamos el lema oficial de EcoRoute
    expect(find.text('Juntos por ciudades más limpias'), findsOneWidget);

    // Verificamos que existan los campos de login (correo y contraseña)
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('Renderiza RegisterScreen con Únete al cambio y los 5 campos requeridos', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(FakeAuthRemoteDataSource()),
        ],
        child: const MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    // Verificamos encabezados
    expect(find.text('Registro de Ciudadano'), findsOneWidget);
    expect(find.text('Únete al cambio'), findsOneWidget);
    expect(find.text('Regístrate para reportar incidentes y contribuir a mantener limpia nuestra ciudad.'), findsOneWidget);

    // Verificamos que existan los 5 campos del formulario de registro
    expect(find.byType(TextFormField), findsNWidgets(5));
    expect(find.text('Crear Cuenta'), findsOneWidget);
    expect(find.text('Inicia sesión'), findsOneWidget);
  });
}
