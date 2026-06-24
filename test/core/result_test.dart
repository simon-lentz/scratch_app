import 'package:checkplan/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guard wraps a successful action in Ok', () async {
    final result = await Result.guard(() async => 42);
    expect(result, isA<Ok<int>>());
    expect((result as Ok<int>).value, 42);
  });

  test('guard maps a thrown Exception to Err', () async {
    final result = await Result.guard<int>(
      () async => throw const FormatException('bad'),
    );
    expect(result, isA<Err<int>>());
    expect((result as Err<int>).error, isA<FormatException>());
  });

  test('guard lets Error subtypes propagate (not buried in a value)', () async {
    await expectLater(
      Result.guard<int>(() async => throw StateError('bug')),
      throwsStateError,
    );
  });
}
