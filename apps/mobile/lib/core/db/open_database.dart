import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import 'app_database.dart';
import 'database_key.dart';

/// True when the browser offers no persistent storage and the database runs in memory: the app then
/// works online only and says so (spec §24).
final ephemeralDatabase = ValueNotifier<bool>(false);

/// Opens the app database: SQLCipher-encrypted on Android/iOS, WASM SQLite on web
/// (no secure key storage in browsers; nothing sensitive is stored there, spec §22.8).
Future<AppDatabase> openAppDatabase() async {
  final key = kIsWeb ? null : await loadOrCreateDatabaseKey();
  final executor = driftDatabase(
    name: 'plengo',
    native: DriftNativeOptions(
      setup: (db) {
        if (key == null) return;
        db.execute("PRAGMA key = \"x'$key'\"");
        // Fails fast if the build is not linked against SQLCipher.
        final version = db.select('PRAGMA cipher_version');
        if (version.isEmpty) throw StateError('SQLCipher is not available');
      },
    ),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
      onResult: (result) => ephemeralDatabase.value = result.chosenImplementation == WasmStorageImplementation.inMemory,
    ),
  );
  return AppDatabase(executor);
}

/// For tests.
AppDatabase inMemoryDatabase(QueryExecutor executor) => AppDatabase(executor);
