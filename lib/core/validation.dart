import 'package:checkplan/core/result.dart';

/// The maximum length of a checklist or task title.
const int maxTitleLength = 200;

/// Validates a raw title from an editor: trims, then rejects empty or
/// over-length input.
///
/// Returns null when [raw] is valid, otherwise a human-readable reason.
String? titleError(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'Title cannot be empty';
  if (trimmed.length > maxTitleLength) {
    return 'Title must be $maxTitleLength characters or fewer';
  }
  return null;
}

/// Thrown across the write boundary when a title fails [titleError].
///
/// Carries the human-readable [message] from [titleError] so a controller can
/// reject invalid input as an `Err` before the database is touched, instead of
/// leaning on the DB length constraint as control flow.
class ValidationException implements Exception {
  /// Creates a validation failure carrying a human-readable [message].
  const ValidationException(this.message);

  /// The human-readable reason the input was rejected (from [titleError]).
  final String message;
}

/// Runs a title-validated write: validates [title] with [titleError] and, on
/// failure, returns an [Err] wrapping a [ValidationException] without running
/// [action]. Otherwise runs [action] with the trimmed title under
/// [Result.guard] — a caught exception becomes an [Err]; a programming `Error`
/// propagates. Shared by every controller's create/rename/add/edit command so
/// the validate-then-guard contract lives in one place.
Future<Result<T>> guardTitle<T>(
  String title,
  Future<T> Function(String title) action,
) {
  final error = titleError(title);
  if (error != null) return Future.value(Err(ValidationException(error)));
  return Result.guard(() => action(title.trim()));
}
