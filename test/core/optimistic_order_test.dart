import 'package:checkplan/core/optimistic_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // In these tests an item is its own id.
  int idOf(int x) => x;

  test('passes the stream order through when nothing is pending', () {
    final order = OptimisticOrder();
    expect(order.reconcile([1, 2, 3], idOf), [1, 2, 3]);
    expect(order.hasPending, isFalse);
  });

  test('overrides with the optimistic order while the stream lags', () {
    final order = OptimisticOrder()..apply([2, 1, 3]);
    // The stream still emits the pre-reorder order; the optimistic order wins.
    expect(order.reconcile([1, 2, 3], idOf), [2, 1, 3]);
    expect(order.hasPending, isTrue);
  });

  test('clears the pending order once the stream catches up', () {
    final order = OptimisticOrder()..apply([2, 1, 3]);
    expect(order.reconcile([2, 1, 3], idOf), [2, 1, 3]); // stream now matches
    expect(order.hasPending, isFalse);
  });

  test('drops the pending order when the stream changes shape', () {
    final order = OptimisticOrder()..apply([2, 1, 3]);
    // An item was removed upstream: the optimistic order is stale, stream wins.
    expect(order.reconcile([1, 2], idOf), [1, 2]);
    expect(order.hasPending, isFalse);
  });

  test('clear() rolls back to the stream order', () {
    final order = OptimisticOrder()
      ..apply([2, 1, 3])
      ..clear();
    expect(order.reconcile([1, 2, 3], idOf), [1, 2, 3]);
    expect(order.hasPending, isFalse);
  });
}
