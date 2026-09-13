import '../errors/failures.dart';

/// Envoltorio funcional para resultados de operaciones en Clean Architecture.
/// 
/// Ubicación: `lib/core/utils/result.dart`
/// Capa: Core (Utils)
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  T? get dataOrNull => switch (this) {
    Success<T>(data: final d) => d,
    FailureResult<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    FailureResult<T>(failure: final f) => f,
  };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(data: final d) => onSuccess(d),
      FailureResult<T>(failure: final f) => onFailure(f),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class FailureResult<T> extends Result<T> {
  final Failure failure;
  const FailureResult(this.failure);
}
