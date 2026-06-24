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
