import 'package:flutter/material.dart';

/// The empty state for a list screen: a centred [message].
class EmptyView extends StatelessWidget {
  /// Creates an empty-state view showing [message].
  const EmptyView({required this.message, super.key});

  /// The text shown when the list has no items.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}
