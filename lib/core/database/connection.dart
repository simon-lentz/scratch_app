import 'package:checkplan/core/database/app_database.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Opens the app's on-disk database as `checkplan.sqlite` under the platform's
/// application-documents directory (native SQLite via drift_flutter).
///
/// `drift_flutter` opens lazily, so a failed open surfaces on the first query
/// and the "Lists" screen's error state renders it.
// coverage:ignore-start
AppDatabase openAppDatabase() => AppDatabase(driftDatabase(name: 'checkplan'));
// coverage:ignore-end
