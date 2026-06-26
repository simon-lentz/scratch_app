import 'package:checkplan/core/database/summaries.dart';
import 'package:flutter/material.dart';

/// A single row in the Lists screen: title, task-progress bar, and an overflow
/// menu of actions.
///
/// A leaf widget that takes its data and callbacks as parameters and reads no
/// providers, so it is easy to test in isolation.
class ChecklistTile extends StatelessWidget {
  /// Creates a checklist row from [summary] and its action callbacks.
  const ChecklistTile({
    required this.summary,
    required this.onRename,
    required this.onRecolor,
    required this.onArchive,
    required this.onDelete,
    required this.onOpen,
    super.key,
  });

  /// The checklist and its task progress.
  final ChecklistSummary summary;

  /// Invoked when the user chooses Rename.
  final VoidCallback onRename;

  /// Invoked when the user chooses Recolor.
  final VoidCallback onRecolor;

  /// Invoked when the user chooses Archive.
  final VoidCallback onArchive;

  /// Invoked when the user chooses Delete.
  final VoidCallback onDelete;

  /// Invoked when the user taps the row to open the checklist's detail.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final (done, total) = summary.progress;
    final colorValue = summary.checklist.colorValue;
    return ListTile(
      onTap: onOpen,
      leading: CircleAvatar(
        backgroundColor: colorValue == null ? null : Color(colorValue),
      ),
      title: Text(summary.checklist.title),
      subtitle: total == 0
          ? const Text('No tasks')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$done/$total'),
                LinearProgressIndicator(value: done / total),
              ],
            ),
      trailing: PopupMenuButton<_ChecklistAction>(
        onSelected: (action) => switch (action) {
          _ChecklistAction.rename => onRename(),
          _ChecklistAction.recolor => onRecolor(),
          _ChecklistAction.archive => onArchive(),
          _ChecklistAction.delete => onDelete(),
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: _ChecklistAction.rename, child: Text('Rename')),
          PopupMenuItem(
            value: _ChecklistAction.recolor,
            child: Text('Recolor'),
          ),
          PopupMenuItem(
            value: _ChecklistAction.archive,
            child: Text('Archive'),
          ),
          PopupMenuItem(value: _ChecklistAction.delete, child: Text('Delete')),
        ],
      ),
    );
  }
}

enum _ChecklistAction { rename, recolor, archive, delete }

/// The fixed palette offered when recoloring a checklist.
const List<Color> checklistPalette = [
  Colors.red,
  Colors.orange,
  Colors.green,
  Colors.blue,
  Colors.purple,
];

/// The outcome of [showRecolorDialog]: the chosen [color], where null means
/// "clear to the default color".
///
/// A dismissed dialog returns no choice at all (the future completes with
/// null), so the caller can tell "cleared to default" from "cancelled".
class RecolorChoice {
  /// Wraps the chosen [color] (null -> clear to the default color).
  const RecolorChoice(this.color);

  /// The picked color, or null to clear back to the default.
  final Color? color;
}

/// Shows the recolor picker. Resolves to a [RecolorChoice] (a swatch, or
/// Default to clear), or null if the dialog is dismissed.
Future<RecolorChoice?> showRecolorDialog(BuildContext context) {
  return showDialog<RecolorChoice>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Recolor'),
      children: [
        for (final color in checklistPalette)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(RecolorChoice(color)),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: color, radius: 12),
                const SizedBox(width: 12),
                Text('#${color.toARGB32().toRadixString(16).toUpperCase()}'),
              ],
            ),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(const RecolorChoice(null)),
          child: const Text('Default'),
        ),
      ],
    ),
  );
}
