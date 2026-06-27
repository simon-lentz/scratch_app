import 'package:flutter/material.dart';

/// The empty state for a list screen: a centered [icon] above a [message], with
/// an optional call-to-action [action] beneath.
class EmptyView extends StatelessWidget {
  /// Creates an empty-state view showing [message] under [icon].
  const EmptyView({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    super.key,
  });

  /// The text shown when the list has no items.
  final String message;

  /// The glyph shown above [message].
  final IconData icon;

  /// An optional call-to-action shown beneath [message], or null for none.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (action case final action?) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
