import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklists_screen.dart';

/// A controller whose commands all fail by default, to drive the view's error
/// feedback. Reads still come from a real in-memory DB, so a row renders to act
/// on. Set [archiveSucceeds] for the archive->Undo path: archive returns [Ok]
/// (so the Undo snackbar shows) while restore still fails.
class _FailingController extends ChecklistController {
  _FailingController({this.archiveSucceeds = false});

  final bool archiveSucceeds;

  static Err<T> _boom<T>() => Err(Exception('boom'));

  @override
  Future<Result<int>> create(String title) async => _boom();
  @override
  Future<Result<void>> rename(int id, String title) async => _boom();
  @override
  Future<Result<void>> setColor(int id, int? colorValue) async => _boom();
  @override
  Future<Result<void>> archive(int id) async =>
      archiveSucceeds ? const Ok(null) : _boom();
  @override
  Future<Result<void>> restore(int id) async => _boom();
  @override
  Future<Result<void>> reorder(List<int> orderedIds) async => _boom();
  @override
  Future<Result<void>> delete(int id) async => _boom();
}

Future<void> pumpWithController(
  WidgetTester tester,
  ChecklistController Function() controller,
) async {
  final db = memoryDb();
  await db.checklistDao.create('Item');
  await pumpChecklistsScreen(
    tester,
    db: db,
    overrides: [checklistControllerProvider.overrideWith(controller)],
  );
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

  testWidgets('recolor failure shows an error', (tester) async {
    await pumpWithController(tester, _FailingController.new);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recolor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#FF2196F3'));
    await tester.pumpAndSettle();
    expect(find.text('Could not update the color'), findsOneWidget);
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
    await pumpChecklistsScreen(
      tester,
      db: db,
      overrides: [
        checklistControllerProvider.overrideWith(_FailingController.new),
      ],
    );
    final reorderable = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    reorderable.onReorderItem!(0, 1);
    await tester.pumpAndSettle();
    expect(find.text('Could not reorder the checklists'), findsOneWidget);
  });

  testWidgets('Undo->restore failure shows an error', (tester) async {
    await pumpWithController(
      tester,
      () => _FailingController(archiveSucceeds: true),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Could not restore the checklist'), findsOneWidget);
  });
}
