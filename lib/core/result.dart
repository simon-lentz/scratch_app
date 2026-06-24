/// The outcome of a fallible write command: [Ok] on success, [Err] on a
/// caught failure.
///
/// Reads surface errors as `AsyncError`; writes cross the layer boundary as a
/// `Result` value the caller pattern-matches, rather than as a thrown exception
/// a caller might forget to catch.
sealed class Result<T> {
  /// Const base constructor for the sealed hierarchy.
  const Result();

  /// Runs [action], returning [Ok] with its value, or [Err] wrapping a thrown
  /// [Exception].
  ///
  /// `Error` subtypes propagate uncaught because they signal programming bugs,
  /// not recoverable conditions a caller should handle as a value.
  static Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Exception catch (error) {
      return Err(error);
    }
  }
}

/// A successful [Result] carrying its [value].
final class Ok<T> extends Result<T> {
  /// Wraps a success [value].
  const Ok(this.value);

  /// The value produced by the action.
  final T value;
}

/// A failed [Result] carrying the caught [error].
///
/// Named `Err` (not `Error`) to avoid shadowing `dart:core`'s `Error`.
final class Err<T> extends Result<T> {
  /// Wraps a caught [error].
  const Err(this.error);

  /// The exception the action threw.
  final Object error;
}
