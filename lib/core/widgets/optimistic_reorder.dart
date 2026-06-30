import 'package:checkplan/core/optimistic_order.dart';
import 'package:checkplan/core/reordering.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:flutter/widgets.dart';

/// A [State] mixin carrying the optimistic-reorder protocol shared by every
/// reorderable list in the app (checklists, tasks, subtasks): reflect a
/// just-dropped order immediately, persist it, and roll back to the stream's
/// order with an error snackbar if the write fails.
mixin OptimisticReorder<T extends StatefulWidget> on State<T> {
  /// Applies a drag-drop reorder of [currentIds] (moving [oldIndex] to
  /// [newIndex]) through [order] optimistically, persists it via [persist], and
  /// restores the stream's order with [errorMessage] if the write returns an
  /// [Err].
  Future<void> applyReorder({
    required List<int> currentIds,
    required int oldIndex,
    required int newIndex,
    required OptimisticOrder order,
    required Future<Result<void>> Function(
      int movedId,
      int? beforeId,
      int? afterId,
    )
    persist,
    required String errorMessage,
  }) async {
    final ids = reorderedIds(currentIds, oldIndex, newIndex);
    setState(() => order.apply(ids)); // show the new order this frame
    // The moved row and its new neighbours (null at a list end): the persist
    // call re-ranks it to sit strictly between them, a single-row write.
    final movedId = ids[newIndex];
    final beforeId = newIndex > 0 ? ids[newIndex - 1] : null;
    final afterId = newIndex < ids.length - 1 ? ids[newIndex + 1] : null;
    final result = await persist(movedId, beforeId, afterId);
    if (!mounted) return;
    if (result case Err()) {
      setState(order.clear); // write failed — fall back to the stream's order
      showErrorSnackBar(context, errorMessage);
    }
  }
}
