import 'package:checkplan/core/observability/logging_provider_observer.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logs a provider being added and its state changing', () {
    final logs = <String>[];
    final counter = StateProvider<int>((ref) => 0);
    final container = ProviderContainer(
      observers: [
        LoggingProviderObserver(
          sink: (message, {error, stackTrace}) => logs.add(message),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(counter); // first read -> didAddProvider(…, 0)
    container.read(counter.notifier).state = 1; // -> didUpdateProvider(…, 0, 1)

    expect(logs.any((l) => l.startsWith('+') && l.contains('0')), isTrue);
    expect(logs.any((l) => l.contains('0 → 1')), isTrue);
  });

  test('logs a provider being disposed', () {
    final logs = <String>[];
    final counter = StateProvider<int>((ref) => 0);
    // Mount the provider, then dispose the container -> didDisposeProvider.
    ProviderContainer(
        observers: [
          LoggingProviderObserver(
            sink: (message, {error, stackTrace}) => logs.add(message),
          ),
        ],
      )
      ..read(counter)
      ..dispose();

    expect(logs.any((l) => l.startsWith('-')), isTrue);
  });

  test('logs a provider failure with its originating stack trace', () {
    final logs = <String>[];
    StackTrace? capturedStack;
    final boom = Provider<int>((ref) => throw StateError('boom'));
    final container = ProviderContainer(
      observers: [
        LoggingProviderObserver(
          sink: (message, {error, stackTrace}) {
            logs.add(message);
            if (stackTrace != null) capturedStack = stackTrace;
          },
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(() => container.read(boom), throwsA(isA<ProviderException>()));
    expect(logs.any((l) => l.startsWith('!') && l.contains('boom')), isTrue);
    // The originating stack trace must be forwarded to the sink, not dropped.
    expect(capturedStack, isNotNull);
  });

  test('truncates on a code-point boundary, not mid-surrogate', () {
    final logs = <String>[];
    // toString is > 80 code units with an emoji straddling the 77-unit cut; a
    // code-unit substring would keep a lone (replacement-glyph) surrogate.
    final value = '${'a' * 76}😀${'b' * 10}';
    final provider = StateProvider<String>((ref) => value);
    final container = ProviderContainer(
      observers: [
        LoggingProviderObserver(
          sink: (message, {error, stackTrace}) => logs.add(message),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(provider);

    // The truncated line carries the ellipsis; it must hold no unpaired
    // surrogate (no rune in the UTF-16 surrogate range).
    final line = logs.firstWhere((l) => l.contains('…'));
    expect(line.runes.any((r) => r >= 0xD800 && r <= 0xDFFF), isFalse);
  });

  test('the default dart:developer sink runs without throwing', () {
    final counter = StateProvider<int>((ref) => 0);
    final container = ProviderContainer(
      observers: [const LoggingProviderObserver()],
    );
    addTearDown(container.dispose);

    expect(() {
      container.read(counter);
      container.read(counter.notifier).state = 1;
    }, returnsNormally);
  });

  test('does not append an ellipsis when the value fits in 80 runes', () {
    final logs = <String>[];
    // 41 astral characters: 82 UTF-16 code units but only 41 runes, so it fits
    // the 80-rune cap and must render in full — a code-unit length test would
    // wrongly truncate it and append a phantom ellipsis.
    final value = '😀' * 41;
    final provider = StateProvider<String>((ref) => value);
    final container = ProviderContainer(
      observers: [
        LoggingProviderObserver(
          sink: (message, {error, stackTrace}) => logs.add(message),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(provider);

    final line = logs.firstWhere((l) => l.startsWith('+'));
    expect(line.contains('…'), isFalse);
    expect(line, contains(value));
  });

  test('logs a mutation lifecycle and its failure stack trace', () async {
    final logs = <String>[];
    StackTrace? capturedStack;
    final container = ProviderContainer(
      observers: [
        LoggingProviderObserver(
          sink: (message, {error, stackTrace}) {
            logs.add(message);
            if (stackTrace != null) capturedStack = stackTrace;
          },
        ),
      ],
    );
    addTearDown(container.dispose);

    // A successful run -> start + success(result).
    final ok = Mutation<int>();
    await ok.run(container, (_) async => 42);
    expect(logs.any((l) => l.contains('mutation: started')), isTrue);
    expect(logs.any((l) => l.contains('mutation: 42')), isTrue);

    // A failure routes to mutationError (not providerDidFail), and must be
    // logged with its originating stack trace rather than dropped.
    final boom = Mutation<void>();
    try {
      await boom.run(container, (_) async => throw StateError('boom'));
    } on Object catch (_) {
      // run rethrows; the observer has already logged the failure.
    }
    expect(logs.any((l) => l.startsWith('!') && l.contains('boom')), isTrue);
    expect(capturedStack, isNotNull);

    // Resetting clears the mutation's state -> reset.
    ok.reset(container);
    expect(logs.any((l) => l.contains('mutation: reset')), isTrue);
  });
}
