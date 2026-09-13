import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ecoroute/features/auth/data/models/user_dto.dart';
import 'package:ecoroute/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ecoroute/features/auth/presentation/views/login_screen.dart';

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

    // Verificamos que se muestre el nombre de la app y el lema
    expect(find.text('EcoRoute'), findsOneWidget);
    expect(find.text('"Juntos por ciudades más limpias"'), findsOneWidget);

    // Verificamos que existan los campos de login
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
