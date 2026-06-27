import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/features/checklists/presentation/checklists_screen.dart';
import 'package:drift/drift.dart' show DatabaseConnection, LazyDatabase;
import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a failed open recovers when the user taps Retry', (
    tester,
  ) async {
    var opens = 0;
    AppDatabase open() {
      opens++;
      if (opens == 1) {
        // The open throws; drift surfaces it on the first query.
        return AppDatabase(
          LazyDatabase(() => throw Exception('open failed')),
        );
      }
      return AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseOverride(open)],
        child: const MaterialApp(home: ChecklistsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Something went wrong'), findsNothing);
    expect(find.text('No checklists yet'), findsOneWidget);
    expect(opens, 2);
  });
}
