import 'package:flutter/material.dart';

/// The error state for a stream-backed screen: a centred message that includes
/// the [error]'s description.
class StreamErrorView extends StatelessWidget {
  /// Creates an error view for [error].
  const StreamErrorView({required this.error, super.key});

  /// The error emitted by the stream read.
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Something went wrong:\n$error'));
  }
}
