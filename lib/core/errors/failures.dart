/// Representación abstracta de fallos en el sistema.
/// 
/// Ubicación: `lib/core/errors/failures.dart`
/// Capa: Core (Errors)
abstract class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Fallo proveniente de servicios de servidor / Firebase
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Fallo de autenticación o permisos
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Fallo en operaciones de almacenamiento (Firebase Storage)
class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

/// Fallo de geolocalización o permisos de GPS
class LocationFailure extends Failure {
  const LocationFailure({required super.message, super.code});
}

/// Fallo de conectividad a internet
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// Fallo de validación de datos
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}
