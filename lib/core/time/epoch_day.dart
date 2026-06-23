/// A timezone-free calendar date: days since the Unix epoch (1970-01-01).
///
/// The right model for a due date, i.e. "the 18th" in the user's
/// own frame, not an instant.
///
/// In this format dates compare and subtract as plain
/// integers, with no offset or DST. Contrast [DateTime.timestamp], the model
/// for an instant such as `createdAt`.
extension type const EpochDay(int value) {
  /// The civil date that [local]'s calendar components fall on, independent of
  /// timezone. Builds the components as UTC so the result is a clean day index.
  factory EpochDay.fromDateTime(DateTime local) {
    final utcMidnight = DateTime.utc(local.year, local.month, local.day);
    return EpochDay(
      utcMidnight.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay,
    );
  }

  /// This date as a local-midnight `DateTime`, for formatting/display.
  DateTime toLocalDateTime() {
    final utcMidnight = DateTime.fromMillisecondsSinceEpoch(
      value * Duration.millisecondsPerDay,
      isUtc: true,
    );
    return DateTime(utcMidnight.year, utcMidnight.month, utcMidnight.day);
  }

  /// Whole days from [other] to this date (negative if earlier).
  int operator -(EpochDay other) => value - other.value;

  /// True if this date is strictly before [other].
  bool operator <(EpochDay other) => value < other.value;
}
