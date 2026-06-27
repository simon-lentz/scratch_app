// Platform-conditional `deleteAppDatabase`: the native build (dart:io) removes
// the on-disk database file; off-native (the web) falls back to a stub, so
// `dart:io` is never imported into a web build. Reset is not offered on web.
export 'database_reset_stub.dart' if (dart.library.io) 'database_reset_io.dart';
