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

/// Classifies a task's [dueDay] (an [EpochDay], or null) against [today].
///
/// Because both are zero-based epoch-days, the comparison is exact integer
/// arithmetic (no timezone or DST involved).
DueStatus dueStatusFor(EpochDay? dueDay, EpochDay today) {
  if (dueDay == null) return const NoDueDate();
  if (dueDay < today) return Overdue(today - dueDay);
  if (dueDay > today) return Upcoming(dueDay);
  return const DueToday();
}

/// A short human label for [status].
///
/// [Upcoming] shows the local month/day (e.g. `Due 6/28`), reconstructed from
/// the zone-free [EpochDay] for display only.
String describe(DueStatus status) {
  switch (status) {
    case NoDueDate():
      return 'No date';
    case Overdue(:final days):
      return 'Overdue ${days}d';
    case DueToday():
      return 'Today';
    case Upcoming(:final on):
      final d = on.toLocalDateTime();
      return 'Due ${d.month}/${d.day}';
  }
}
