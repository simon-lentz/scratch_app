import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CheckPlanApp launches on the empty Lists screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(
            AppDatabase(
              // closeStreamsSynchronously avoids post-test timer errors.
              DatabaseConnection(
                NativeDatabase.memory(),
                closeStreamsSynchronously: true,
              ),
            ),
          ),
        ],
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lists'), findsOneWidget); // app-bar title
    expect(find.text('No checklists yet'), findsOneWidget); // empty state
  });
}
