import 'package:checkplan/core/time/epoch_day.dart';
import 'package:drift/drift.dart';

/// Maps the `dueDay` column between its stored `int` epoch-day and the
/// timezone-free [EpochDay] domain type, so drift's generated `Task` row
/// exposes `EpochDay? dueDay` end-to-end instead of a raw `int`.
///
/// A [TypeConverter] changes only the Dart mapping; the SQL column stays
/// `INTEGER` — no schema change.
class EpochDayConverter extends TypeConverter<EpochDay, int> {
  /// Creates the converter. `const` so it can be passed to `.map(...)` on the
  /// column definition.
  const EpochDayConverter();

  @override
  EpochDay fromSql(int fromDb) => EpochDay(fromDb);

  @override
  int toSql(EpochDay value) => value.value;
}
