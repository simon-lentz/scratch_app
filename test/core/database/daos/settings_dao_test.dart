import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/daos/settings_dao.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SettingsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.settingsDao;
  });
  tearDown(() => db.close());

  test('watchValue emits null for an unset key', () async {
    expect(await dao.watchValue('theme_mode').first, isNull);
  });

  test('setValue then watchValue reflects the stored value', () async {
    await dao.setValue('theme_mode', 'dark');
    expect(await dao.watchValue('theme_mode').first, 'dark');
  });

  test('setValue upserts — a second write updates, not duplicates', () async {
    await dao.setValue('theme_mode', 'dark');
    await dao.setValue('theme_mode', 'light');
    expect(await dao.watchValue('theme_mode').first, 'light');
    expect(await db.select(db.settings).get(), hasLength(1));
  });

  test('watchValue re-emits when the value changes', () async {
    final expectation = expectLater(
      dao.watchValue('theme_mode'),
      emitsThrough('light'),
    );
    await dao.setValue('theme_mode', 'dark');
    await dao.setValue('theme_mode', 'light');
    await expectation;
  });
}
