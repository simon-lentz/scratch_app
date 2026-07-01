import 'package:checkplan/core/database/converters/epoch_day_converter.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const converter = EpochDayConverter();

  test('fromSql wraps the stored int as an EpochDay', () {
    expect(converter.fromSql(20262), const EpochDay(20262));
  });

  test('toSql unwraps the EpochDay to its int value', () {
    expect(converter.toSql(const EpochDay(20262)), 20262);
  });
}
