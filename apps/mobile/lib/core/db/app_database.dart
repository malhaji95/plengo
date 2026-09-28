import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Small key/value store for settings and cache metadata. Feature tables (SRS states, review
/// logs, exam drafts, student decks, offline packs) arrive with their phases (§22.12).
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Local spaced-repetition state (spec §13.6). Scheduling runs on the device; rows sync to the
/// server and come back from other devices (last review wins). `flashcardId` holds the card key:
/// an official card id, or `u:<id>` for the student's own cards (see `SrsKey`).
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

/// The student's own decks (spec §13.9). Ids are generated here so decks work offline; `dirty` rows
/// have local changes the server has not accepted yet. Times are epoch milliseconds (UTC).
@DataClassName('LocalDeckRow')
class LocalDecks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get sortOrder => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Cards in the student's decks. A face shows its text and/or image: `*ImageJson` is the server's
/// signed image (with its cache key), `*LocalImage` the picked bytes still waiting to upload.
/// `official_ref` cards keep the official images they were added with so they render offline.
@DataClassName('LocalCardRow')
class LocalCards extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text()();
  TextColumn get kind => text()();
  TextColumn get officialFlashcardId => text().nullable()();
  TextColumn get frontText => text().nullable()();
  TextColumn get backText => text().nullable()();
  TextColumn get frontMediaId => text().nullable()();
  TextColumn get backMediaId => text().nullable()();
  TextColumn get frontImageJson => text().nullable()();
  TextColumn get backImageJson => text().nullable()();
  BlobColumn get frontLocalImage => blob().nullable()();
  BlobColumn get backLocalImage => blob().nullable()();
  BoolColumn get locked => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A downloaded (or downloading) offline pack (spec §22). `version` is what the device holds;
/// `remoteVersion` the latest the server reported, so a difference means "تحديث متاح".
@DataClassName('OfflinePackRow')
class OfflinePacks extends Table {
  TextColumn get packKey => text()();
  TextColumn get scopeType => text()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get teacherTrackId => text().nullable()();
  TextColumn get scopeTitle => text()();
  TextColumn get kind => text()();
  TextColumn get unitId => text().nullable()();
  TextColumn get deckId => text().nullable()();
  TextColumn get titleAr => text()();

  /// queued | downloading | paused | waiting_wifi | ready | failed
  TextColumn get status => text()();
  TextColumn get version => text().nullable()();
  TextColumn get remoteVersion => text().nullable()();
  BoolColumn get premium => boolean().withDefault(const Constant(false))();
  IntColumn get normalizationVersion => integer().nullable()();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {packKey};
}

/// One item of a pack: a question, deck, card or quiz as the server sent it (JSON), with its version.
@DataClassName('OfflineItemRow')
class OfflineItems extends Table {
  TextColumn get packKey => text()();
  TextColumn get itemId => text()();
  TextColumn get type => text()();
  IntColumn get version => integer()();
  BoolColumn get isFree => boolean()();
  TextColumn get json => text()();

  @override
  Set<Column<Object>> get primaryKey => {packKey, itemId};
}

/// An encrypted image file of a pack card (AES-GCM, §22.5).
@DataClassName('OfflineFileRow')
class OfflineFiles extends Table {
  TextColumn get packKey => text()();
  TextColumn get mediaId => text()();
  IntColumn get version => integer()();
  TextColumn get path => text()();
  IntColumn get sizeBytes => integer()();

  @override
  Set<Column<Object>> get primaryKey => {packKey, mediaId};
}

/// The device's lease for a scope's premium pack content (§22.4). Scope key: `subject:<id>` or
/// `teacher_track:<id>`.
@DataClassName('OfflineLeaseRow')
class OfflineLeaseRows extends Table {
  TextColumn get scopeKey => text()();
  IntColumn get expiresAt => integer()();
  IntColumn get refreshedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {scopeKey};
}

/// An attempt taken from downloaded packs (§22.6). `attempt` is the `Attempt` JSON the screens use;
/// `payload` the upload body once submitted. Kept until the server has it.
@DataClassName('LocalAttemptRow')
class LocalAttempts extends Table {
  TextColumn get id => text()();
  TextColumn get attempt => text()();
  TextColumn get payload => text().nullable()();
  BoolColumn get submitted => boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  TextColumn get serverAttemptId => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Questions answered wrong offline, a local mirror of the mistake bank until the server has them.
@DataClassName('LocalMistakeRow')
class LocalMistakes extends Table {
  TextColumn get questionId => text()();
  IntColumn get wrongAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {questionId};
}

@DriftDatabase(
  tables: [
    KeyValues,
    SrsCardStates,
    SrsReviewLogs,
    ExamDrafts,
    ExamAnswers,
    LocalDecks,
    LocalCards,
    OfflinePacks,
    OfflineItems,
    OfflineFiles,
    OfflineLeaseRows,
    LocalAttempts,
    LocalMistakes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 5;

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
      if (from < 4) {
        await m.createTable(localDecks);
        await m.createTable(localCards);
      }
      if (from < 5) {
        for (final TableInfo<Table, Object?> table in [
          offlinePacks,
          offlineItems,
          offlineFiles,
          offlineLeaseRows,
          localAttempts,
          localMistakes,
        ]) {
          await m.createTable(table);
        }
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
