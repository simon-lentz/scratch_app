import 'dart:async';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/model/due_status.dart';
import 'package:checkplan/core/widgets/due_date_chip.dart';
import 'package:checkplan/core/widgets/labeled_checkbox.dart';
import 'package:flutter/material.dart';

/// A single Today row: a done checkbox, the task title, its parent checklist,
/// and an optional due-date chip.
///
/// Checking it off completes the task, which removes it from Today. To give
/// that completion a beat of feedback instead of a blink-out, the row ticks its
/// box and strikes through the title immediately, plays a short collapse/fade,
/// and only then commits via [onComplete] — so the task leaves the Today stream
/// once the row has already animated away. A failed write restores it.
///
/// A leaf widget that takes its data and callback as parameters and reads no
/// providers.
class TodayTaskTile extends StatefulWidget {
  /// Creates a Today row from [entry], with an optional due-[status] chip.
  const TodayTaskTile({
    required this.entry,
    required this.onComplete,
    this.status,
    super.key,
  });

  /// The due task and the title of its parent checklist.
  final TodayTask entry;

  /// Completes the task when its box is checked; resolves to whether the write
  /// succeeded, so a failed completion can restore the row.
  final Future<bool> Function() onComplete;

  /// The due status to show as a chip, or null to omit it — the Today section
  /// omits the chip because its header already says the tasks are due today.
  final DueStatus? status;

  @override
  State<TodayTaskTile> createState() => _TodayTaskTileState();
}

class _TodayTaskTileState extends State<TodayTaskTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..addStatusListener(_onExitStatus);

  // Drives both the collapse and the fade: 1 (full) -> 0 (gone) as _exit runs.
  late final Animation<double> _shrink = Tween<double>(
    begin: 1,
    end: 0,
  ).animate(CurvedAnimation(parent: _exit, curve: Curves.easeIn));

  bool _completing = false;

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  void _complete() {
    // A re-tap while the exit animation is already running is a no-op.
    if (_completing) return;
    setState(() => _completing = true);
    unawaited(_exit.forward());
  }

  Future<void> _onExitStatus(AnimationStatus status) async {
    if (status != AnimationStatus.completed) return;
    // Commit only after the row has ticked and collapsed: on success the task
    // drops out of the Today stream and this tile unmounts (already invisible);
    // on failure, restore the row.
    final ok = await widget.onComplete();
    if (!ok && mounted) {
      setState(() => _completing = false);
      _exit.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final status = widget.status;
    return SizeTransition(
      sizeFactor: _shrink,
      child: FadeTransition(
        opacity: _shrink,
        child: ListTile(
          leading: LabeledCheckbox(
            label: 'Toggle "${entry.task.title}" done',
            value: _completing,
            onChanged: (_) => _complete(),
          ),
          title: Text(
            entry.task.title,
            style: _completing
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: Text(entry.checklistTitle),
          trailing: status == null ? null : DueDateChip(status: status),
        ),
      ),
    );
  }
}
