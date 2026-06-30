import 'package:checkplan/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  // The verifier spins up several short-lived databases alongside AppDatabase.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('the latest snapshot matches the current AppDatabase schema', () async {
    // Build a database at the latest committed snapshot, open the current
    // AppDatabase over it, and assert the live schema matches what the code
    // would create. Fails the day a schema change skips the `drift_schemas/`
    // snapshot step (see drift_schemas/README.md).
    final schema = await verifier.schemaAt(GeneratedHelper.versions.last);
    final db = AppDatabase(schema.newConnection());
    await db.validateDatabaseSchema();
    await db.close();
  });

  test('migrating v1 -> v2 produces the expected schema', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

  test("v1 -> v2 backfills rank from each scope's position order", () async {
    // A non-null ISO string: dates are stored as TEXT, and the migration copies
    // them through untouched, so the exact value is irrelevant.
    const ts = '2026-01-01T00:00:00.000Z';
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      // Seed each scope out of position order, so a correct backfill must
      // reorder: global for checklists, per checklist for tasks, per task for
      // subtasks.
      createItems: (batch, oldDb) {
        batch
          ..insertAll(oldDb.checklists, [
            v1.ChecklistsCompanion.insert(
              id: const Value(1),
              title: 'A',
              position: 1,
              createdAt: ts,
              updatedAt: ts,
            ),
            v1.ChecklistsCompanion.insert(
              id: const Value(2),
              title: 'B',
              position: 0,
              createdAt: ts,
              updatedAt: ts,
            ),
          ])
          ..insertAll(oldDb.tasks, [
            v1.TasksCompanion.insert(
              id: const Value(1),
              checklistId: 1,
              title: 't-late',
              position: 1,
              createdAt: ts,
              updatedAt: ts,
            ),
            v1.TasksCompanion.insert(
              id: const Value(2),
              checklistId: 1,
              title: 't-early',
              position: 0,
              createdAt: ts,
              updatedAt: ts,
            ),
          ])
          ..insertAll(oldDb.subtasks, [
            v1.SubtasksCompanion.insert(
              id: const Value(1),
              taskId: 1,
              title: 's-late',
              position: 1,
              createdAt: ts,
              updatedAt: ts,
            ),
            v1.SubtasksCompanion.insert(
              id: const Value(2),
              taskId: 1,
              title: 's-early',
              position: 0,
              createdAt: ts,
              updatedAt: ts,
            ),
          ]);
      },
      validateItems: (newDb) async {
        final checklists = await (newDb.select(
          newDb.checklists,
        )..orderBy([(c) => OrderingTerm(expression: c.rank)])).get();
        expect(checklists.map((c) => c.title), ['B', 'A']);

        final tasks =
            await (newDb.select(newDb.tasks)
                  ..where((t) => t.checklistId.equals(1))
                  ..orderBy([(t) => OrderingTerm(expression: t.rank)]))
                .get();
        expect(tasks.map((t) => t.title), ['t-early', 't-late']);

        final subtasks =
            await (newDb.select(newDb.subtasks)
                  ..where((s) => s.taskId.equals(1))
                  ..orderBy([(s) => OrderingTerm(expression: s.rank)]))
                .get();
        expect(subtasks.map((s) => s.title), ['s-early', 's-late']);
      },
    );
  });
}
