import 'package:checkplan/core/reordering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moves an entry towards the tail', () {
    expect(reorderedIds([1, 2, 3], 0, 2), [2, 3, 1]);
  });

  test('moves an entry towards the head', () {
    expect(reorderedIds([1, 2, 3], 2, 0), [3, 1, 2]);
  });

  test('is a no-op when the indices match', () {
    expect(reorderedIds([1, 2, 3], 1, 1), [1, 2, 3]);
  });

  test('does not mutate the input list', () {
    final ids = [1, 2, 3];
    reorderedIds(ids, 0, 2);
    expect(ids, [1, 2, 3]);
  });
}
