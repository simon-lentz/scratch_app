import 'package:flutter/material.dart';

/// A [Checkbox] with a merged semantic [label], so a screen reader announces
/// the control by name instead of as an unlabelled toggle.
///
/// Centralises the accessibility contract shared by the app's done-toggle
/// checkboxes (task, subtask, and Today rows): each is wrapped in
/// [MergeSemantics] + [Semantics] so its label and checked state read as one
/// node, and the tristate value is coerced to a plain `bool` — [onChanged]
/// receives `false` for the indeterminate case.
class LabeledCheckbox extends StatelessWidget {
  /// Creates a labelled checkbox showing [value], announced as [label].
  const LabeledCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The semantic label announced for the checkbox.
  final String label;

  /// Whether the checkbox is currently checked.
  final bool value;

  /// Invoked with the new checked state when the user toggles the checkbox.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      label: label,
      child: Checkbox(
        value: value,
        onChanged: (value) => onChanged(value ?? false),
      ),
    ),
  );
}
