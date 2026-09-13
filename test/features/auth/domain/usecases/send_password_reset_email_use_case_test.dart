import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/utils/result.dart';
import 'package:ecoroute/features/auth/domain/entities/user_entity.dart';
import 'package:ecoroute/features/auth/domain/repositories/auth_repository.dart';
import 'package:ecoroute/features/auth/domain/usecases/send_password_reset_email_use_case.dart';

class MockAuthRepository implements AuthRepository {
  String? lastSentEmail;

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    lastSentEmail = email;
    return const Success(null);
  }

  @override
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Result<UserEntity>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.citizen,
    String? phoneNumber,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> signOut() => throw UnimplementedError();

  @override
  Future<Result<UserEntity?>> getCurrentUser() => throw UnimplementedError();

  @override
  Stream<UserEntity?> authStateChanges() => throw UnimplementedError();
}

void main() {
  late SendPasswordResetEmailUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SendPasswordResetEmailUseCase(mockRepository);
  });

  test('debe retornar ValidationFailure si el correo está vacío o no contiene @', () async {
    final resultEmpty = await useCase.call('');
    expect(resultEmpty.isFailure, true);
    expect(resultEmpty.failureOrNull?.message, 'Ingrese un correo electrónico válido');

    final resultInvalid = await useCase.call('usuario-sin-arroba');
    expect(resultInvalid.isFailure, true);
    expect(resultInvalid.failureOrNull?.message, 'Ingrese un correo electrónico válido');
  });

  test('debe retornar Success y llamar al repositorio con correo limpio cuando es válido', () async {
    final result = await useCase.call('   test@ecoroute.app  ');
    expect(result.isSuccess, true);
    expect(mockRepository.lastSentEmail, 'test@ecoroute.app');
  });
}
