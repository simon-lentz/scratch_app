/// Returns a copy of [ids] with the entry at [oldIndex] moved to [newIndex].
///
/// Pairs with the `onReorderItem` callback of `ReorderableListView`, which
/// already adjusts [newIndex] for the entry removed at [oldIndex]. The input
/// list is not mutated.
List<int> reorderedIds(List<int> ids, int oldIndex, int newIndex) {
  final reordered = [...ids];
  final moved = reordered.removeAt(oldIndex);
  reordered.insert(newIndex, moved);
  return reordered;
}
