import 'package:checkplan/app/app.dart';
import 'package:checkplan/features/settings/application/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/memory_db.dart';
import '../support/test_overrides.dart';

void main() {
  testWidgets('CheckPlanApp applies the persisted theme mode', (tester) async {
    final db = memoryDb();
    await db.settingsDao.setValue(themeModeKey, themeModeName(ThemeMode.dark));

    await tester.pumpWidget(
      ProviderScope(
        // baseTestOverrides pins appDatabaseProvider to `db` and
        // currentDayProvider to a fixed day, so no midnight Timer is armed.
        overrides: baseTestOverrides(db: db),
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
