import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _memory() => AppDatabase(
  DatabaseConnection(
    NativeDatabase.memory(),
    closeStreamsSynchronously: true,
  ),
);

void main() {
  test('appDatabaseOverride rebuilds a fresh database on invalidate', () {
    var built = 0;
    final container = ProviderContainer.test(
      overrides: [
        appDatabaseOverride(() {
          built++;
          return _memory();
        }),
      ],
    );

    final first = container.read(appDatabaseProvider);
    container.invalidate(appDatabaseProvider);
    final second = container.read(appDatabaseProvider);

    expect(built, 2);
    expect(identical(first, second), isFalse);
  });
}
