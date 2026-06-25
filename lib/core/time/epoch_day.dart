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
  ///
  /// Pass a local [DateTime] such as `DateTime.now()`; a UTC DateTime is
  /// rejected by [assert] in debug builds, because its UTC calendar components
  /// rarely match the user's local day.
  factory EpochDay.fromDateTime(DateTime local) {
    assert(
      !local.isUtc,
      'EpochDay.fromDateTime needs a local DateTime; a UTC one yields the '
      'UTC civil day, not the local one',
    );
    final utcMidnight = DateTime.utc(local.year, local.month, local.day);
    return EpochDay(
      utcMidnight.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay,
    );
  }

  /// This date as a local `DateTime` anchored at noon, for formatting/display.
  ///
  /// Noon, not midnight: in a timezone whose DST transition skips local
  /// midnight (e.g. clocks springing 00:00 -> 01:00), `DateTime(y, m, d)` is
  /// normalised forward off midnight, which can drift the time-of-day or the
  /// civil date. Local noon exists in every timezone on every day, so the
  /// calendar date is always preserved. Use [EpochDay] arithmetic for date
  /// logic; this is for display only.
  DateTime toLocalDateTime() {
    final utcDay = DateTime.fromMillisecondsSinceEpoch(
      value * Duration.millisecondsPerDay,
      isUtc: true,
    );
    return DateTime(utcDay.year, utcDay.month, utcDay.day, 12);
  }

  /// Whole days from [other] to this date (negative if earlier).
  int operator -(EpochDay other) => value - other.value;

  /// True if this date is strictly before [other].
  bool operator <(EpochDay other) => value < other.value;

  /// True if this date is on or before [other].
  bool operator <=(EpochDay other) => value <= other.value;

  /// True if this date is strictly after [other].
  bool operator >(EpochDay other) => value > other.value;

  /// True if this date is on or after [other].
  bool operator >=(EpochDay other) => value >= other.value;
}
