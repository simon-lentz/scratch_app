import 'package:checkplan/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

void main() {
  // The verifier spins up several short-lived databases alongside AppDatabase.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('the v1 snapshot matches the current AppDatabase schema', () async {
    // Build a database whose schema is the committed v1 snapshot, then open the
    // current AppDatabase over it and assert the live schema matches what the
    // current code would create. Fails the day a schema change skips the
    // `drift_schemas/` snapshot step (see drift_schemas/README.md).
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase(schema.newConnection());
    await db.validateDatabaseSchema();
    await db.close();
  });
}
