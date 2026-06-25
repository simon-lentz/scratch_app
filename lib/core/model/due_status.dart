import 'package:checkplan/core/time/epoch_day.dart';

/// The status of a task's due date relative to today.
///
/// A `sealed` union so a `switch` over it is exhaustive at compile time.
/// If you add a case to the type every match site must handle it.
sealed class DueStatus {
  const DueStatus();
}

/// The task has no due date.
final class NoDueDate extends DueStatus {
  /// Creates the no-due-date status.
  const NoDueDate();
}

/// The due date is before today, by [days] whole days.
final class Overdue extends DueStatus {
  /// Creates an overdue status [days] days past due.
  const Overdue(this.days);

  /// Whole days the task is overdue (always positive).
  final int days;
}

/// The due date is today.
final class DueToday extends DueStatus {
  /// Creates the due-today status.
  const DueToday();
}

/// The due date is after today, on [on].
final class Upcoming extends DueStatus {
  /// Creates an upcoming status due [on].
  const Upcoming(this.on);

  /// The future day the task is due.
  final EpochDay on;
}

/// Classifies a task's [dueDay] (the raw stored epoch-day, or null) against
/// [today].
///
/// Because both are zero-based epoch-days, the comparison is exact integer
/// arithmetic (no timezone or DST involved).
DueStatus dueStatusFor(int? dueDay, EpochDay today) {
  if (dueDay == null) return const NoDueDate();
  final due = EpochDay(dueDay);
  if (due < today) return Overdue(today - due);
  if (due > today) return Upcoming(due);
  return const DueToday();
}

/// A short human label for [status].
///
/// [Upcoming] shows the local month/day (e.g. `Due 6/28`), reconstructed from
/// the zone-free [EpochDay] for display only.
String describe(DueStatus status) => switch (status) {
  NoDueDate() => 'No date',
  Overdue(:final days) => 'Overdue ${days}d',
  DueToday() => 'Today',
  Upcoming(:final on) =>
    'Due ${on.toLocalDateTime().month}/${on.toLocalDateTime().day}',
};
