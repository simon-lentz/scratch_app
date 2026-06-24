import 'package:checkplan/core/validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a normal title', () => expect(titleError('Groceries'), isNull));

  test('rejects empty and whitespace-only titles', () {
    expect(titleError(''), isNotNull);
    expect(titleError('   '), isNotNull);
  });

  test('rejects titles longer than the maximum', () {
    expect(titleError('a' * (maxTitleLength + 1)), isNotNull);
    expect(titleError('a' * maxTitleLength), isNull);
  });
}
