import 'package:checkplan/core/database/app_database.dart';
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
            rank: 'a0',
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
            rank: 'a1',
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

  test('reorder moves a checklist to the head, before its old first', () async {
    final a = await dao.create('A');
    await dao.create('B');
    final c = await dao.create('C');
    // Move C to the front: nothing above it, A below it.
    await dao.reorder(c, null, a);

    final titles = (await dao.watchActiveSummaries().first)
        .map((s) => s.checklist.title)
        .toList();
    expect(titles, ['C', 'A', 'B']);
  });

  test(
    'reorder between equal-ranked neighbours rebalances and honors the drop',
    () async {
      // A rank collision is impossible single-device but expected once sync
      // merges two devices that each appended the same deterministic key. Force
      // B and C onto the same rank, then drag A into the gap rankBetween cannot
      // split: the reorder must not throw, must honor the drop, and must leave
      // every rank distinct again.
      final a = await dao.create('A');
      final b = await dao.create('B');
      final c = await dao.create('C');
      await (db.update(db.checklists)..where((t) => t.id.equals(b))).write(
        const ChecklistsCompanion(rank: Value('a1')),
      );
      await (db.update(db.checklists)..where((t) => t.id.equals(c))).write(
        const ChecklistsCompanion(rank: Value('a1')),
      );
      // By (rank, id) the active order is [A, B, C]; drop A between B and C.
      await dao.reorder(a, b, c);

      final summaries = await dao.watchActiveSummaries().first;
      expect(summaries.map((s) => s.checklist.title), ['B', 'A', 'C']);
      final ranks = summaries.map((s) => s.checklist.rank).toList();
      expect(ranks.toSet().length, summaries.length); // all distinct again
    },
  );

  test(
    'rebalancing the active order leaves archived checklists untouched',
    () async {
      Future<String> rankOf(int id) async => (await (db.select(
        db.checklists,
      )..where((c) => c.id.equals(id))).getSingle()).rank;

      final a = await dao.create('A');
      final b = await dao.create('B');
      final c = await dao.create('C');
      final archived = await dao.create('Z');
      await dao.archive(archived);
      final archivedRankBefore = await rankOf(archived);

      // Collide b and c, then drop a between them: the rebalance covers the
      // active scope only, so the archived row's rank must not move.
      await (db.update(db.checklists)..where((t) => t.id.equals(b))).write(
        const ChecklistsCompanion(rank: Value('a1')),
      );
      await (db.update(db.checklists)..where((t) => t.id.equals(c))).write(
        const ChecklistsCompanion(rank: Value('a1')),
      );
      await dao.reorder(a, b, c);

      expect(await rankOf(archived), archivedRankBefore);
    },
  );

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
            rank: 'a0',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await dao.deleteById(id);

    expect(await db.select(db.tasks).get(), isEmpty);
  });

  test('restore re-ranks to the active tail, not its stale rank', () async {
    // gone ranks before keep at creation; archived then restored, it must
    // re-rank to the tail so it sorts after keep, not back at the head.
    final gone = await dao.create('gone');
    await dao.create('keep');
    await dao.archive(gone);
    await dao.restore(gone);

    final summaries = await dao.watchActiveSummaries().first;
    expect(summaries.map((s) => s.checklist.title), ['keep', 'gone']);
    final ranks = summaries.map((s) => s.checklist.rank).toList();
    expect(ranks.toSet().length, summaries.length); // all ranks unique
  });

  test('watchArchivedSummaries lists archived and excludes active', () async {
    await dao.create('Active');
    final archived = await dao.create('Archived');
    await dao.archive(archived);

    final summaries = await dao.watchArchivedSummaries().first;
    expect(summaries.map((s) => s.checklist.title), ['Archived']);
  });

  test('restoring removes the checklist from the archived list', () async {
    final id = await dao.create('Temp');
    await dao.archive(id);
    expect(await dao.watchArchivedSummaries().first, hasLength(1));

    await dao.restore(id);
    expect(await dao.watchArchivedSummaries().first, isEmpty);
  });

  test('deleting removes the checklist from the archived list', () async {
    final id = await dao.create('Doomed');
    await dao.archive(id);
    expect(await dao.watchArchivedSummaries().first, hasLength(1));

    await dao.deleteById(id);
    expect(await dao.watchArchivedSummaries().first, isEmpty);
  });

  test('archived list is ordered most-recently-archived first', () async {
    final first = await dao.create('First');
    final second = await dao.create('Second');
    await dao.archive(first);
    await dao.archive(second);

    final titles = (await dao.watchArchivedSummaries().first)
        .map((s) => s.checklist.title)
        .toList();
    expect(titles, ['Second', 'First']);
  });

  test('watchRowById emits the row for an active checklist', () async {
    final id = await dao.create('Groceries');
    final row = await dao.watchRowById(id).first;
    expect(row?.title, 'Groceries');
  });

  test(
    'watchRowById resolves an archived checklist, not only active',
    () async {
      final id = await dao.create('Old');
      await dao.archive(id);
      final row = await dao.watchRowById(id).first;
      expect(row?.title, 'Old');
      expect(row?.archivedAt, isNotNull);
    },
  );

  test('watchRowById emits null for a missing id', () async {
    expect(await dao.watchRowById(999).first, isNull);
  });
}
