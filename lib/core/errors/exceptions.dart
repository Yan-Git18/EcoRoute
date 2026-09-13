/// Excepciones técnicas lanzadas por la capa Data.
/// 
/// Ubicación: `lib/core/errors/exceptions.dart`
/// Capa: Core (Errors)
class ServerException implements Exception {
  final String message;
  final String? code;
  const ServerException({required this.message, this.code});
}

class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException({required this.message, this.code});
}

class StorageException implements Exception {
  final String message;
  final String? code;
  const StorageException({required this.message, this.code});
}

class LocationException implements Exception {
  final String message;
  final String? code;
  const LocationException({required this.message, this.code});
}
