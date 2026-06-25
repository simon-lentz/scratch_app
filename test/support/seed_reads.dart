import 'package:checkplan/core/database/app_database.dart';

/// One-shot seed/verification reads for **widget** tests.
///
/// Widget tests run under flutter_test's fake-async clock, where a drift
/// `.watch()` stream's first emission never arrives without a `pump` — so
/// `await dao.watch….first` hangs to the test timeout. Fetch
/// seed rows with these one-shot `.get()` reads instead, and assert reactive UI
/// via `pumpAndSettle` + `find`. (A `no_drift_stream_await_in_widget_tests`
/// guard test fails the suite if a `.watch()` stream is awaited in a
/// `testWidgets` body.)
extension SeedReads on AppDatabase {
  /// Every task row, read once (not a stream).
  Future<List<Task>> readTasks() => select(tasks).get();

  /// The one and only task row; throws if there is not exactly one.
  Future<Task> readSingleTask() async => (await select(tasks).get()).single;
}
