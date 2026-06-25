import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/dao_support.dart';
import 'package:checkplan/core/database/daos/checklist_dao.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ChecklistDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.checklistDao;
  });
  tearDown(() => db.close());

  test(
    'create then watchActiveSummaries re-emits with the new checklist',
    () async {
      // Initial empty snapshot races the awaited create(); assert the stream
      // emits through to the post-write state, not the first event.
      final expectation = expectLater(
        dao.watchActiveSummaries(),
        emitsThrough(
          predicate<List<ChecklistSummary>>(
            (list) =>
                list.length == 1 &&
                list.single.checklist.title == 'Groceries' &&
                list.single.progress == (0, 0),
          ),
        ),
      );
      await dao.create('Groceries');
      await expectation;
    },
  );

  test('progress counts done vs total tasks', () async {
    final id = await dao.create('Chores');
    final now = DateTime.timestamp();
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            checklistId: id,
            title: 'a',
            position: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            checklistId: id,
            title: 'b',
            position: 1,
            createdAt: now,
            updatedAt: now,
            isDone: const Value(true),
          ),
        );

    final summaries = await dao.watchActiveSummaries().first;
    expect(summaries.single.progress, (1, 2));
  });

  test('archive hides from active; restore brings it back', () async {
    final id = await dao.create('Temp');
    await dao.archive(id);
    expect(await dao.watchActiveSummaries().first, isEmpty);
    await dao.restore(id);
    expect(await dao.watchActiveSummaries().first, hasLength(1));
  });

  test('reorder rewrites positions to match the given order', () async {
    final a = await dao.create('A');
    final b = await dao.create('B');
    final c = await dao.create('C');
    await dao.reorder([c, a, b]);

    final titles = (await dao.watchActiveSummaries().first)
        .map((s) => s.checklist.title)
        .toList();
    expect(titles, ['C', 'A', 'B']);
  });

  test('setColor sets then clears the color', () async {
    final id = await dao.create('Palette');

    await dao.setColor(id, 0xFF2196F3);
    final colored = await (db.select(
      db.checklists,
    )..where((c) => c.id.equals(id))).getSingle();
    expect(colored.colorValue, 0xFF2196F3);

    await dao.setColor(id, null);
    final cleared = await (db.select(
      db.checklists,
    )..where((c) => c.id.equals(id))).getSingle();
    expect(cleared.colorValue, isNull);
  });

  test('rename changes the title', () async {
    final id = await dao.create('Old name');
    await dao.rename(id, 'Fresh name');
    final row = await (db.select(
      db.checklists,
    )..where((c) => c.id.equals(id))).getSingle();
    expect(row.title, 'Fresh name');
  });

  test('deleting a checklist cascades to its tasks (FK pragma)', () async {
    final id = await dao.create('Doomed');
    final now = DateTime.timestamp();
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            checklistId: id,
            title: 'orphan?',
            position: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await dao.deleteById(id);

    expect(await db.select(db.tasks).get(), isEmpty);
  });

  test('reorder rejects a partial id set', () async {
    final a = await dao.create('A');
    await dao.create('B');
    await dao.create('C');
    // Omitting B and C would leave them colliding on stale positions.
    await expectLater(dao.reorder([a]), throwsA(isA<ReorderConflict>()));
  });

  test(
    'restore re-slots position so it cannot collide after a reorder',
    () async {
      final keep = await dao.create('keep'); // position 0
      final gone = await dao.create('gone'); // position 1
      await dao.archive(gone);
      await dao.reorder([keep]); // keep -> 0; gone keeps stale 1 while archived
      await dao.restore(gone); // must move to the tail, not tie keep at 0

      final summaries = await dao.watchActiveSummaries().first;
      final positions = summaries.map((s) => s.checklist.position).toList();
      expect(
        positions.toSet().length,
        summaries.length,
      ); // all positions unique
      expect(
        summaries.map((s) => s.checklist.title),
        ['keep', 'gone'],
      ); // deterministic order
    },
  );
}
