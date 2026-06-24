import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';

void main() {
  // A container whose database is a fresh in-memory drift DB it owns and
  // closes (overrideWithValue would leak the DB).
  ProviderContainer makeContainer() =>
      ProviderContainer.test(overrides: [memoryDbOverride()]);

  test('appDatabaseProvider throws until it is overridden', () {
    // No override: the un-overridden provider must refuse to build, so a
    // forgotten override fails loudly. Riverpod surfaces the create fn's
    // UnimplementedError wrapped in a ProviderException when it is read.
    final container = ProviderContainer.test();
    expect(
      () => container.read(appDatabaseProvider),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.exception,
          'exception',
          isA<UnimplementedError>(),
        ),
      ),
    );
  });

  test('activeChecklistsProvider starts empty', () async {
    // An active listener keeps the StreamProvider subscribed; Riverpod pauses
    // a provider once all its listeners are gone, which would strand `.future`
    // in loading. ProviderContainer.test disposes the listener at test end.
    final container = makeContainer()
      ..listen(activeChecklistsProvider, (_, _) {});
    final summaries = await container.read(activeChecklistsProvider.future);
    expect(summaries, isEmpty);
  });

  test(
    'a checklist created via the DAO appears in the read provider',
    () async {
      final container = makeContainer();
      await container.read(checklistDaoProvider).create('Groceries');

      // Subscribe only after the write: this fresh subscription's first
      // emission already reflects the new row — deterministic, with no race
      // against a later re-emission. (Listening before the write would emit
      // the empty snapshot first, and `.future` could resolve to that stale
      // value.) The listener also keeps the provider active so `.future`
      // resolves instead of pausing in loading.
      container.listen(activeChecklistsProvider, (_, _) {});
      final summaries = await container.read(activeChecklistsProvider.future);
      expect(summaries.single.checklist.title, 'Groceries');
      expect(summaries.single.progress, (0, 0));
    },
  );
}
