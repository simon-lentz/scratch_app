import 'dart:io';

import 'package:checkplan/core/database/connection.dart';
import 'package:path_provider/path_provider.dart';

/// Deletes the on-disk database file and its WAL sidecars (`-wal`, `-shm`) so
/// the next open starts from an empty database. Native (`dart:io`) build.
///
/// The path mirrors drift_flutter's native default: `$databaseName.sqlite`
/// under the application-documents directory (the native targets join with
/// `/`).
// coverage:ignore-start
Future<void> deleteAppDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  final base = '${directory.path}/$databaseName.sqlite';
  for (final path in [base, '$base-wal', '$base-shm']) {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

// coverage:ignore-end
