# Schema migrations (drift)

Snapshots of each `schemaVersion` of `AppDatabase` live under `app_database/` (the drift-CLI database
key, set in `build.yaml`). The matching schema-test fixtures live under `test/drift/app_database/`.

## How the harness is wired

- `build.yaml` declares the database for the drift CLI: under `drift_dev.options`,
  `databases: { app_database: lib/core/database/app_database.dart }`, `schema_dir: drift_schemas/`,
  `test_dir: test/drift/`.
- `test/drift/app_database/generated/` holds drift-generated fixtures (`GeneratedHelper`,
  `DatabaseAtV<N>`) — **excluded from analysis** (`analysis_options.yaml`) because the generator emits
  raw types. `test/drift/app_database/migration_test.dart` is **hand-maintained**.
- `SchemaVerifier` / `validateDatabaseSchema()` come from `package:drift_dev/api/migrations_native.dart`
  — **test-only** (drift_dev is a dev-dependency; importing it from `lib/` would force it into runtime
  deps and trip `depend_on_referenced_packages`).

## Adding a migration (every `schemaVersion` bump)

1. Edit the table(s) under `lib/core/database/tables/`.
2. Bump `schemaVersion` in `lib/core/database/app_database.dart`.
3. `dart run drift_dev make-migrations` — with **≥2 versions** this dumps the new
   `drift_schemas/app_database/drift_schema_v<N>.json`, regenerates `test/drift/app_database/generated/`
   (with versioned data classes), writes/updates `lib/core/database/app_database.steps.dart`, and
   refreshes the migration-test template.
4. Wire `onUpgrade` in `app_database.dart` to the generated steps, **inside the foreign-key window** (the
   `foreign_keys` pragma can't toggle inside a transaction — disable it *first*, run steps in a
   `transaction`, check, re-enable):

   ```dart
   import 'package:checkplan/core/database/app_database.steps.dart';
   // ...
   @override
   MigrationStrategy get migration => MigrationStrategy(
     onCreate: (m) => m.createAll(),
     onUpgrade: (m, from, to) async {
       await customStatement('PRAGMA foreign_keys = OFF');
       await transaction(() => m.runMigrationSteps(
             from: from,
             to: to,
             steps: migrationSteps(
               from1To2: (m, schema) async {
                 // ...the v1 -> v2 migration logic...
               },
             ),
           ));
       // Run the FK check unconditionally (cheap, one-time); the assert strips
       // in release. Avoid kDebugMode so app_database.dart stays Flutter-free
       // and schema dump needs no --export-schema-startup-code workaround.
       final bad = await customSelect('PRAGMA foreign_key_check').get();
       assert(bad.isEmpty, '${bad.map((e) => e.data)}');
       await customStatement('PRAGMA foreign_keys = ON');
     },
     beforeOpen: (details) async {
       await customStatement('PRAGMA foreign_keys = ON');
     },
   );
   ```
5. Fill the `from<N>To<N+1>` step with the `Migrator` API (`addColumn`,
   `alterTable(TableMigration(...))`, `createTable`, `recreateAllViews`, …); each step sees the schema
   **at its target version** via `schema`.
6. Extend `test/drift/app_database/migration_test.dart`: an all-pairs `migrateAndValidate` loop over
   `GeneratedHelper.versions`, plus a `verifier.testWithDataIntegrity(oldVersion: N, newVersion: N+1, …)`
   case (seed with `DatabaseAtV<N>`, validate with `DatabaseAtV<N+1>`).
7. `dart run build_runner build`, then the gate (`dart format … && flutter analyze && flutter test`).
8. Commit the source **+ the regenerated `app_database.g.dart` + the new snapshot + the regenerated
   fixtures** together. CI's "verify committed generated code is current" runs **`build_runner`** only —
   it does *not* run `make-migrations`, so the snapshot/fixtures must be committed but aren't re-checked.

## Column-type changes (the `alterTable` index trap)

Changing a column's type or name needs `m.alterTable(TableMigration(schema.t))`, which rebuilds the
table by copying columns **by name** from the old table into a new one. Two sharp edges:

- **Drop the table's stale indexes that reference the changed column _before_ `alterTable`.** alterTable
  re-creates every index it finds in `sqlite_master` by replaying that index's stored `CREATE INDEX` SQL
  **verbatim** after the rebuild — so an index on the old column re-issues `CREATE INDEX … (old_col)`
  against a table that no longer has it (`no such column`). Drop it first (`DROP INDEX IF EXISTS …`), then
  create the new `(…, new_col)` index afterward via `m.createIndex(schema.theIndex)` (the generated
  `Index` carries the right DDL). Indexes on _unchanged_ columns (e.g. `task_due`) replay fine — leave
  them.
- **A new NOT NULL column whose value is data-dependent can't be a `columnTransformer`** (that's pure
  SQL). Add it nullable with a raw `ALTER TABLE … ADD COLUMN`, backfill in Dart via
  `m.database.customSelect` / `customUpdate` — raw SQL **by column name**, because the typed accessors
  reflect the _latest_ schema, which the table doesn't match mid-migration — then `alterTable` to finalize
  (the now-populated column copies over to satisfy NOT NULL; the old column, absent from the target shape,
  is dropped).

For the data-integrity test: versioned companions store dates as **TEXT** (pass ISO strings, not
`DateTime`), and `testWithDataIntegrity` disables foreign keys for the run — still seed FK-valid rows so
the migration's own `PRAGMA foreign_key_check` stays clean.

## Re-capturing fixtures by hand (single schema version)

At a **single** `schemaVersion`, `make-migrations` only **dumps the snapshot** — it generates no fixtures
or steps file (there are no version transitions to diff). To (re)build the test fixtures explicitly:

```bash
dart run drift_dev schema generate drift_schemas/app_database/ test/drift/app_database/generated/
# add --data-classes --companions when a data-integrity test needs the versioned row types
```

## Constraints

- **Keep the `@DriftDatabase` graph Flutter-free** — `make-migrations`/`schema dump` run under the Dart
  VM; a Flutter import reachable from the schema breaks the dump (diagnose with
  `dart run drift_dev make-migrations --export-schema-startup-code=schema_description.dart` then
  `dart run schema_description.dart`).
- **`validateDatabaseSchema()` is test-only** (drift_dev is a dev-dependency).
