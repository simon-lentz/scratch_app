import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/widgets/stream_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A reactive screen body that cross-fades between an [AsyncValue]'s loading,
/// empty, error, and data states.
///
/// Centralises the body shared by the Lists, Detail, and Today screens: an
/// [AnimatedSwitcher] with one stable key per state, an error arm whose Retry
/// re-opens the database (`ref.invalidate(appDatabaseProvider)`), and a loading
/// spinner. The error arm is matched first, and any state that *carries* a
/// value renders [data] — so a reload that retains its previous value (e.g. the
/// Today midnight rollover) keeps the list on screen instead of blanking back
/// to a spinner.
class AsyncSwitcher<T> extends ConsumerWidget {
  /// Creates a body for [value], showing [empty] when [isEmpty] holds for the
  /// loaded value and [data] otherwise.
  const AsyncSwitcher({
    required this.value,
    required this.isEmpty,
    required this.empty,
    required this.data,
    super.key,
  });

  /// The reactive value to render.
  final AsyncValue<T> value;

  /// Whether a loaded value should show [empty] rather than [data].
  final bool Function(T value) isEmpty;

  /// The widget shown when a loaded value is empty.
  final Widget empty;

  /// Builds the widget shown for a loaded, non-empty value.
  final Widget Function(T value) data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: switch (value) {
      AsyncError(:final error) => StreamErrorView(
        key: const ValueKey('error'),
        error: error,
        onRetry: () => ref.invalidate(appDatabaseProvider),
      ),
      AsyncValue(:final value?) when isEmpty(value) => KeyedSubtree(
        key: const ValueKey('empty'),
        child: empty,
      ),
      AsyncValue(:final value?) => KeyedSubtree(
        key: const ValueKey('data'),
        child: data(value),
      ),
      _ => const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      ),
    },
  );
}
