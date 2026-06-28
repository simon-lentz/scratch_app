import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock.g.dart';

/// A source of the current wall-clock instant, injected so date logic is
/// testable.
///
/// A function typedef rather than a one-member class.
/// The app binds [DateTime.now]; tests bind a
/// fixed function.
typedef Clock = DateTime Function();

/// The injectable [Clock].
///
/// Returns [DateTime.now] in the app; override it in tests with a fixed
/// **local-time** function so the date logic is deterministic.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => DateTime.now;
