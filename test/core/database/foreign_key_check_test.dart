import 'package:checkplan/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('checkNoForeignKeyViolations', () {
    test('returns normally when there are no violations', () {
      expect(() => checkNoForeignKeyViolations([], 1, 2), returnsNormally);
    });

    test('throws a StateError naming the migration and the rows', () {
      expect(
        () => checkNoForeignKeyViolations(
          [
            {'table': 'tasks', 'rowid': 5, 'parent': 'checklists', 'fkid': 0},
          ],
          1,
          2,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('v1->v2'), contains('tasks')),
          ),
        ),
      );
    });
  });
}
