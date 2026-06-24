import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/validation.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer.test(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          final db = AppDatabase(NativeDatabase.memory());
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
  });

  ChecklistController controller() =>
      container.read(checklistControllerProvider.notifier);

  // Read current state via a fresh DAO stream subscription: its first emission
  // reflects every prior write, so there is no race with provider re-emission.
  Future<List<String>> titles() async {
    final dao = container.read(checklistDaoProvider);
    final summaries = await dao.watchActiveSummaries().first;
    return summaries.map((s) => s.checklist.title).toList();
  }

  Future<int?> singleColor() async {
    final dao = container.read(checklistDaoProvider);
    final summaries = await dao.watchActiveSummaries().first;
    return summaries.single.checklist.colorValue;
  }

  test('create returns Ok with the new id and trims the title', () async {
    final result = await controller().create('  Groceries  ');
    expect(result, isA<Ok<int>>());
    expect(await titles(), ['Groceries']);
  });

  test('create rejects a blank title at the controller boundary', () async {
    final result = await controller().create('   ');
    expect(result, isA<Err<int>>());
    final error = (result as Err<int>).error;
    expect(error, isA<ValidationException>());
    expect((error as ValidationException).message, 'Title cannot be empty');
  });

  test('create rejects an over-length title at the controller', () async {
    final result = await controller().create('a' * (maxTitleLength + 1));
    expect(result, isA<Err<int>>());
    expect((result as Err<int>).error, isA<ValidationException>());
  });

  test('rename rejects a blank title at the controller', () async {
    final id = ((await controller().create('Valid')) as Ok<int>).value;
    final result = await controller().rename(id, '   ');
    expect(result, isA<Err<void>>());
    expect((result as Err<void>).error, isA<ValidationException>());
  });

  test('rename updates the title', () async {
    final id = ((await controller().create('Old')) as Ok<int>).value;
    await controller().rename(id, 'New');
    expect(await titles(), ['New']);
  });

  test('setColor sets then clears the colour', () async {
    final id = ((await controller().create('Palette')) as Ok<int>).value;
    await controller().setColor(id, 0xFF2196F3);
    expect(await singleColor(), 0xFF2196F3);
    await controller().setColor(id, null);
    expect(await singleColor(), isNull);
  });

  test('archive hides; restore brings it back', () async {
    final id = ((await controller().create('Temp')) as Ok<int>).value;
    await controller().archive(id);
    expect(await titles(), isEmpty);
    await controller().restore(id);
    expect(await titles(), ['Temp']);
  });

  test('reorder changes the order', () async {
    final a = ((await controller().create('A')) as Ok<int>).value;
    final b = ((await controller().create('B')) as Ok<int>).value;
    await controller().reorder([b, a]);
    expect(await titles(), ['B', 'A']);
  });

  test('delete removes the checklist', () async {
    final id = ((await controller().create('Doomed')) as Ok<int>).value;
    await controller().delete(id);
    expect(await titles(), isEmpty);
  });
}
