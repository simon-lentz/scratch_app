import 'package:flutter/foundation.dart';

/// Holds a short-lived optimistic ordering so a reorder shows immediately,
/// before the asynchronous write round-trips back through the data stream.
///
/// `ReorderableListView` keeps no model of the reordered list — it re-renders
/// through the parent's `itemBuilder` at the current indices and assumes the
/// backing data is updated synchronously inside the reorder callback. An
/// asynchronous update (a DB write, then a stream re-emit) instead leaves the
/// list showing the pre-reorder order for the frame(s) in between — a visible
/// flicker. Applying the new order here, synchronously, closes that gap.
///
/// The data stream stays the source of truth: the pending order is dropped as
/// soon as the stream catches up (emits the same order) or changes shape (an
/// item added or removed), so the stream always wins in the end.
class OptimisticOrder {
  List<int>? _pending;

  /// Whether an optimistic order is currently overriding the stream.
  bool get hasPending => _pending != null;

  /// Records [order] as the optimistic order — call right after a reorder, then
  /// rebuild so [reconcile] applies it.
  void apply(List<int> order) => _pending = List.of(order);

  /// Drops any optimistic order — call to roll back after a failed reorder.
  void clear() => _pending = null;

  /// Orders [items] by the pending optimistic order while one is active and it
  /// still covers exactly the same ids; otherwise returns [items] unchanged.
  ///
  /// Reconciles as it reads: the pending order is cleared once the stream has
  /// caught up to it or changed shape, so the stream resumes control.
  List<E> reconcile<E>(List<E> items, int Function(E) idOf) {
    final pending = _pending;
    if (pending == null) return items;

    final streamIds = [for (final item in items) idOf(item)];
    if (listEquals(streamIds, pending)) {
      _pending = null; // the stream caught up; stop overriding
      return items;
    }

    final byId = {for (final item in items) idOf(item): item};
    if (byId.length != pending.length || !pending.every(byId.containsKey)) {
      _pending = null; // shape changed; the stream wins
      return items;
    }
    return [for (final id in pending) byId[id]!];
  }
}
