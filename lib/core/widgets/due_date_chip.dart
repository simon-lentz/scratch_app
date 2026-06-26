import 'package:checkplan/core/model/due_status.dart';
import 'package:flutter/material.dart';

/// A compact chip showing a task's [status], colored by urgency.
///
/// A leaf widget: it takes its [status] and reads no providers. Renders nothing
/// useful for [NoDueDate], callers omit the chip in that case.
class DueDateChip extends StatelessWidget {
  /// Creates a due-date chip for [status].
  const DueDateChip({required this.status, super.key});

  /// The due status this chip renders.
  final DueStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = status is Overdue;
    final fg = overdue ? scheme.onErrorContainer : scheme.onSurfaceVariant;
    final bg = overdue ? scheme.errorContainer : scheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        describe(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
