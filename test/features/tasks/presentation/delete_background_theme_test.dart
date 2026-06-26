import 'package:checkplan/features/tasks/presentation/checklist_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/test_overrides.dart';

void main() {
  testWidgets('the swipe-to-delete background uses the theme error role', (
    tester,
  ) async {
    const sentinel = Color(0xFF123456);
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    await db.taskDao.add(list, 'Milk');

    await tester.pumpWidget(
      ProviderScope(
        overrides: baseTestOverrides(db: db),
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
            ).copyWith(errorContainer: sentinel),
          ),
          home: ChecklistDetailScreen(checklistId: list),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Drag the row left far enough to reveal the background, but not past the
    // dismiss threshold (confirmDismiss would otherwise open the dialog).
    await tester.drag(find.text('Milk'), const Offset(-120, 0));
    await tester.pump();

    // The icon is wrapped directly by the swipe background's ColoredBox, so the
    // nearest ColoredBox ancestor is the one under test. `.first` skips the
    // transparent ColoredBox the page-route transition adds higher in the tree.
    final box = tester.widget<ColoredBox>(
      find
          .ancestor(
            of: find.byIcon(Icons.delete),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(box.color, sentinel);
  });
}
