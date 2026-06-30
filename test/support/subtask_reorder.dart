import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives the inner subtask `ReorderableListView` for [taskId], moving the row
/// at [oldIndex] to [newIndex].
///
/// The detail screen keys that list `'subtasks-$taskId'` so tests can target it
/// unambiguously against the outer task list; `onReorderItem` already
/// pre-adjusts [newIndex]. Invokes the callback directly because a bare drag is
/// a long-press the tester won't perform. Keep the key in sync with the widget.
void reorderSubtask(
  WidgetTester tester,
  int taskId,
  int oldIndex,
  int newIndex,
) {
  final inner = tester.widget<ReorderableListView>(
    find.byKey(ValueKey('subtasks-$taskId')),
  );
  inner.onReorderItem!(oldIndex, newIndex);
}
