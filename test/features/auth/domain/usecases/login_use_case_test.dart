import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/domain/repositories/auth_repository.dart';
import 'package:ecoroute/features/auth/domain/usecases/login_use_case.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return Success(
      UserEntity(
        id: '123',
        name: 'Test Citizen',
        email: email,
        role: UserRole.citizen,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<UserEntity>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.citizen,
    String? phoneNumber,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> signOut() async => const Success(null);

  @override
  Future<Result<UserEntity?>> getCurrentUser() async => const Success(null);

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async => const Success(null);

  @override
  Stream<UserEntity?> authStateChanges() => Stream.value(null);
}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  test('debe retornar ValidationFailure si el correo es inválido', () async {
    final result = await useCase.call(email: 'correo-invalido', password: 'password123');
    expect(result.isFailure, true);
    expect(result.failureOrNull?.message, 'Ingrese un correo electrónico válido');
  });

  test('debe retornar ValidationFailure si la contraseña tiene menos de 6 caracteres', () async {
    final result = await useCase.call(email: 'test@ecoroute.app', password: '123');
    expect(result.isFailure, true);
    expect(result.failureOrNull?.message, 'La contraseña debe tener al menos 6 caracteres');
  });

  test('debe retornar Success con UserEntity cuando las credenciales son válidas', () async {
    final result = await useCase.call(email: 'test@ecoroute.app', password: 'password123');
    expect(result.isSuccess, true);
    expect(result.dataOrNull?.email, 'test@ecoroute.app');
    expect(result.dataOrNull?.role, UserRole.citizen);
  });
}
