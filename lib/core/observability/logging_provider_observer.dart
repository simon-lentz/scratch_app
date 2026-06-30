import 'dart:developer' as developer;

import 'package:flutter_riverpod/experimental/mutation.dart' show Mutation;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A [ProviderObserver] that logs provider and mutation lifecycle and state
/// changes — a thin development aid for debugging reactivity. It is registered
/// in debug builds via `ProviderScope(observers: …)`; each event is written to
/// [sink], which defaults to the `dart:developer` log named `riverpod`.
final class LoggingProviderObserver extends ProviderObserver {
  /// Creates the observer. The app uses the default `dart:developer` logger;
  /// tests inject a capturing [sink].
  const LoggingProviderObserver({this.sink = _developerLog});

  /// Where each formatted event line is written. The `error` and `stackTrace`
  /// args are supplied only for a failure, so the default sink can forward them
  /// to the structured fields of `dart:developer`'s log.
  final void Function(String message, {Object? error, StackTrace? stackTrace})
  sink;

  static void _developerLog(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => developer.log(
    message,
    name: 'riverpod',
    error: error,
    stackTrace: stackTrace,
  );

  String _name(ProviderObserverContext context) =>
      context.provider.name ?? context.provider.runtimeType.toString();

  // Cap a logged value so a large object can't flood the log. Measure and cut
  // on the same unit — runes (code points). Cutting on a rune boundary keeps a
  // surrogate pair intact, and measuring the threshold in runes too means the
  // ellipsis is appended only when runes were actually dropped — a code-unit
  // length test over-counts astral characters and would flag a string that fit.
  // The bounded take walks at most 81 runes, not the whole string. toString()
  // still runs fully to preview the value — cheap enough for a debug observer.
  String _brief(Object? value) {
    final text = value.toString();
    final head = text.runes.take(81).toList();
    if (head.length <= 80) return text;
    return '${String.fromCharCodes(head.take(77))}…';
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) =>
      sink('+ ${_name(context)} = ${_brief(value)}');

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) => sink(
    '~ ${_name(context)}: ${_brief(previousValue)} → ${_brief(newValue)}',
  );

  @override
  void didDisposeProvider(ProviderObserverContext context) =>
      sink('- ${_name(context)}');

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) => sink(
    '! ${_name(context)} threw: $error',
    error: error,
    stackTrace: stackTrace,
  );

  @override
  void mutationStart(
    ProviderObserverContext context,
    Mutation<Object?> mutation,
  ) => sink('» ${_name(context)} mutation: started');

  @override
  void mutationSuccess(
    ProviderObserverContext context,
    Mutation<Object?> mutation,
    Object? result,
  ) => sink('« ${_name(context)} mutation: ${_brief(result)}');

  // A mutation failure routes here, not to providerDidFail (which fires only
  // for a provider's own build/emit failure), so without this override a
  // failed reactive write would be dropped. Forwards the error and its
  // originating stack trace to the sink's structured fields.
  @override
  void mutationError(
    ProviderObserverContext context,
    Mutation<Object?> mutation,
    Object error,
    StackTrace stackTrace,
  ) => sink(
    '! ${_name(context)} mutation threw: $error',
    error: error,
    stackTrace: stackTrace,
  );

  @override
  void mutationReset(
    ProviderObserverContext context,
    Mutation<Object?> mutation,
  ) => sink('· ${_name(context)} mutation: reset');
}
