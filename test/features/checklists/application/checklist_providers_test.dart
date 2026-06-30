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

  test(
    'checklistById resolves from the warm active list on the first read',
    () async {
      final container = makeContainer();
      final id = await container.read(checklistDaoProvider).create('Groceries');
      // Warm the active list, as the lists screen does before navigating to
      // detail.
      container.listen(activeChecklistsProvider, (_, _) {});
      await container.read(activeChecklistsProvider.future);

      // The first synchronous read resolves from the warm list — it does not
      // return null while the by-id row stream's first emission is in flight,
      // so the detail app bar never flashes the fallback title.
      expect(container.read(checklistByIdProvider(id))?.title, 'Groceries');
    },
  );

  test(
    'checklistById resolves an archived checklist via the by-id stream',
    () async {
      final container = makeContainer();
      final id = await container.read(checklistDaoProvider).create('Old');
      await container.read(checklistDaoProvider).archive(id);

      // Absent from the active list; resolves once the by-id row stream emits.
      container.listen(checklistByIdProvider(id), (_, _) {});
      await container.read(checklistRowByIdProvider(id).future);
      expect(container.read(checklistByIdProvider(id))?.title, 'Old');
    },
  );
}
