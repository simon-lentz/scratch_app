import 'package:checkplan/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('inserts and reads back a checklist row', () async {
    final now = DateTime.timestamp();
    final id = await db
        .into(db.checklists)
        .insert(
          ChecklistsCompanion.insert(
            title: 'Groceries',
            position: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );

    final rows = await db.select(db.checklists).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, id);
    expect(rows.single.title, 'Groceries');
    expect(rows.single.archivedAt, isNull);
  });
}
