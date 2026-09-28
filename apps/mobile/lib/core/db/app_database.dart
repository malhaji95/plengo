import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Small key/value store for settings and cache metadata. Feature tables (SRS states, review
/// logs, exam drafts; student decks and offline packs later) arrive with their phases (§22.12).
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Local spaced-repetition state of official cards (spec §13.6). Scheduling runs on the device;
/// rows sync to the server and come back from other devices (last review wins).
class SrsCardStates extends Table {
  TextColumn get flashcardId => text()();
  TextColumn get state => text()();
  IntColumn get step => integer()();
  IntColumn get dueAt => integer()();
  IntColumn get intervalDays => integer()();
  RealColumn get ease => real()();
  IntColumn get reps => integer()();
  IntColumn get lapses => integer()();
  IntColumn get lastReviewedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {flashcardId};
}

/// Every rating, kept until the server has it (spec §13.6). `undone` rows restore `before`.
class SrsReviewLogs extends Table {
  TextColumn get id => text()();
  TextColumn get flashcardId => text()();
  TextColumn get rating => text()();
  TextColumn get before => text()();
  TextColumn get after => text()();
  IntColumn get reviewedAt => integer()();
  IntColumn get durationMs => integer().nullable()();
  BoolColumn get undone => boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// An exam in progress, cached so it continues through connection drops (spec §15.2). `attempt`
/// is the server's attempt JSON; `submitPending` marks a submission waiting for the connection.
@DataClassName('ExamDraftRow')
class ExamDrafts extends Table {
  TextColumn get attemptId => text()();
  TextColumn get attempt => text()();
  BoolColumn get submitPending => boolean().withDefault(const Constant(false))();
  IntColumn get timeSpentMs => integer().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {attemptId};
}

/// The latest local answer per exam question. `dirty` answers have not reached the server yet.
@DataClassName('ExamAnswerRow')
class ExamAnswers extends Table {
  TextColumn get attemptId => text()();
  TextColumn get questionId => text()();
  TextColumn get selectedOptionId => text().nullable()();
  TextColumn get writtenAnswer => text().nullable()();
  BoolColumn get flagged => boolean().withDefault(const Constant(false))();
  IntColumn get timeSpentMs => integer().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {attemptId, questionId};
}

@DriftDatabase(tables: [KeyValues, SrsCardStates, SrsReviewLogs, ExamDrafts, ExamAnswers])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(srsCardStates);
        await m.createTable(srsReviewLogs);
      }
      if (from < 3) {
        await m.createTable(examDrafts);
        await m.createTable(examAnswers);
      }
    },
  );

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
