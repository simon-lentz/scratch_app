import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/memory_db.dart';

void main() {
  testWidgets('CheckPlanApp launches on the empty Lists screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(memoryDb()),
        ],
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lists'), findsOneWidget); // app-bar title
    expect(find.text('No checklists yet'), findsOneWidget); // empty state
  });
}
