/// Fallback `deleteAppDatabase` for platforms without `dart:io` (the web).
///
/// Reset is not offered on the web — the UI hides the button — so this is never
/// invoked; it exists only so `database_reset.dart` compiles without `dart:io`
/// off-native.
Future<void> deleteAppDatabase() async {
  throw UnsupportedError('Database reset is not supported on the web.');
}
