import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Small key/value store for settings and cache metadata. Feature tables (SRS states, review
/// logs, student decks, exam drafts, offline packs) arrive with their phases (spec §22.12).
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [KeyValues])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  Future<String?> getValue(String key) async {
    final row = await (select(keyValues)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) {
    return into(
      keyValues,
    ).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: value, updatedAt: Value(DateTime.now())));
  }

  /// Logout wipes all local learning data (spec §22.5). Device preferences (`settings.*`, e.g.
  /// dark mode and font size) are not personal data and survive.
  Future<void> wipe() async {
    await transaction(() async {
      for (final table in allTables) {
        if (table == keyValues) {
          await (delete(keyValues)..where((t) => t.key.like('settings.%').not())).go();
        } else {
          await delete(table).go();
        }
      }
    });
  }
}
