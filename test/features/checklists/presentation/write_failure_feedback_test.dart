import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/checklists/presentation/checklists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';

/// A controller whose every command fails, to drive the view's error feedback.
/// Reads still come from a real in-memory DB, so a row renders to act on.
class _FailingController extends ChecklistController {
  @override
  Future<Result<int>> create(String title) async => Err(Exception('boom'));
  @override
  Future<Result<void>> rename(int id, String title) async =>
      Err(Exception('boom'));
  @override
  Future<Result<void>> setColor(int id, int? colorValue) async =>
      Err(Exception('boom'));
  @override
  Future<Result<void>> archive(int id) async => Err(Exception('boom'));
  @override
  Future<Result<void>> delete(int id) async => Err(Exception('boom'));
  @override
  Future<Result<void>> reorder(List<int> orderedIds) async =>
      Err(Exception('boom'));
}

/// Archive succeeds (so the Undo snackbar shows) but restore fails, to drive
/// the Undo→restore error path.
class _RestoreFailsController extends ChecklistController {
  @override
  Future<Result<void>> archive(int id) async => const Ok(null);
  @override
  Future<Result<void>> restore(int id) async => Err(Exception('boom'));
}

Future<void> pumpWithController(
  WidgetTester tester,
  ChecklistController Function() controller,
) async {
  final db = memoryDb();
  await db.checklistDao.create('Item');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        checklistControllerProvider.overrideWith(controller),
      ],
      child: const MaterialApp(home: ChecklistsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('create failure shows an error', (tester) async {
    await pumpWithController(tester, _FailingController.new);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'New list');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Could not create the checklist'), findsOneWidget);
  });

  testWidgets('rename failure shows an error', (tester) async {
    await pumpWithController(tester, _FailingController.new);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Renamed');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Could not rename the checklist'), findsOneWidget);
  });

  testWidgets('recolour failure shows an error', (tester) async {
    await pumpWithController(tester, _FailingController.new);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recolour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#FF2196F3'));
    await tester.pumpAndSettle();
    expect(find.text('Could not update the colour'), findsOneWidget);
  });

  testWidgets('archive failure shows an error and not a false success', (
    tester,
  ) async {
    await pumpWithController(tester, _FailingController.new);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('Could not archive the checklist'), findsOneWidget);
    expect(find.textContaining('Archived'), findsNothing);
    expect(find.text('Item'), findsOneWidget); // row stays (DB untouched)
  });

  testWidgets('delete failure shows an error', (tester) async {
    await pumpWithController(tester, _FailingController.new);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Could not delete the checklist'), findsOneWidget);
  });

  testWidgets('reorder failure shows an error', (tester) async {
    final db = memoryDb();
    await db.checklistDao.create('A');
    await db.checklistDao.create('B');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          checklistControllerProvider.overrideWith(_FailingController.new),
        ],
        child: const MaterialApp(home: ChecklistsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final reorderable = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    reorderable.onReorderItem!(0, 1);
    await tester.pumpAndSettle();
    expect(find.text('Could not reorder the checklists'), findsOneWidget);
  });

  testWidgets('Undo→restore failure shows an error', (tester) async {
    await pumpWithController(tester, _RestoreFailsController.new);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Could not restore the checklist'), findsOneWidget);
  });
}
