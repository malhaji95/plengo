import 'package:drift/drift.dart';

import '../api/generated/export.dart';
import '../db/app_database.dart';
import 'study_card.dart';

/// Quotas (spec §12.8), checked on the device too so offline edits fail early.
const userDeckQuota = 50;
const userCardQuota = 5000;
const userCardTextMax = 1000;

int _ms(String iso) => DateTime.parse(iso).millisecondsSinceEpoch;
int? _msOrNull(String? iso) => iso == null ? null : _ms(iso);

typedef DeckWithCount = ({LocalDeckRow deck, int cardCount});

/// The student's decks and cards in the local database (spec §13.9). Every local change marks the
/// row dirty with a new `updated_at`; the sync pushes dirty rows and merges the server's feed.
class MyDecksStore {
  MyDecksStore(this.db, {int Function()? clock}) : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase db;
  final int Function() _clock;
  static const cursorKey = 'my_decks.cursor';

  int now() => _clock();

  // ---- reads ----

  ({JoinedSelectStatement<HasResultSet, dynamic> query, Expression<int> count}) _decksQuery() {
    final count = db.localCards.id.count(filter: db.localCards.deletedAt.isNull());
    final query =
        db.select(db.localDecks).join([
            leftOuterJoin(db.localCards, db.localCards.deckId.equalsExp(db.localDecks.id), useColumns: false),
          ])
          ..addColumns([count])
          ..where(db.localDecks.deletedAt.isNull())
          ..groupBy([db.localDecks.id])
          ..orderBy([OrderingTerm.asc(db.localDecks.sortOrder), OrderingTerm.asc(db.localDecks.createdAt)]);
    return (query: query, count: count);
  }

  List<DeckWithCount> _withCounts(List<TypedResult> rows, Expression<int> count) => [
    for (final r in rows) (deck: r.readTable(db.localDecks), cardCount: r.read(count) ?? 0),
  ];

  Stream<List<DeckWithCount>> watchDecks() {
    final q = _decksQuery();
    return q.query.watch().map((rows) => _withCounts(rows, q.count));
  }

  Future<List<DeckWithCount>> decks() async {
    final q = _decksQuery();
    return _withCounts(await q.query.get(), q.count);
  }

  Stream<LocalDeckRow?> watchDeck(String id) =>
      (db.select(db.localDecks)..where((t) => t.id.equals(id) & t.deletedAt.isNull())).watchSingleOrNull();

  SimpleSelectStatement<$LocalCardsTable, LocalCardRow> _cardsQuery(String deckId) => db.select(db.localCards)
    ..where((t) => t.deckId.equals(deckId) & t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.createdAt)]);

  Stream<List<LocalCardRow>> watchCards(String deckId) => _cardsQuery(deckId).watch();

  Future<List<LocalCardRow>> cards(String deckId) => _cardsQuery(deckId).get();

  Future<LocalCardRow?> card(String id) => (db.select(db.localCards)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<LocalDeckRow?> deck(String id) => (db.select(db.localDecks)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Live cards by id (for the due session and bookmarks).
  Future<List<LocalCardRow>> cardsByIds(Iterable<String> ids) {
    final list = ids.toList();
    if (list.isEmpty) return Future.value(const []);
    return (db.select(db.localCards)..where((t) => t.id.isIn(list) & t.deletedAt.isNull())).get();
  }

  Future<int> liveDeckCount() async =>
      (await (db.select(db.localDecks)..where((t) => t.deletedAt.isNull())).get()).length;

  Future<int> liveCardCount() async =>
      (await (db.select(db.localCards)..where((t) => t.deletedAt.isNull())).get()).length;

  // ---- local edits ----

  Future<void> saveDeck({
    required String id,
    required String name,
    String? subjectId,
    String? color,
    int? sortOrder,
  }) async {
    final existing = await deck(id);
    final at = now();
    await db
        .into(db.localDecks)
        .insertOnConflictUpdate(
          LocalDecksCompanion.insert(
            id: id,
            name: name.trim(),
            subjectId: Value(subjectId),
            color: Value(color),
            sortOrder: sortOrder ?? existing?.sortOrder ?? await liveDeckCount(),
            createdAt: existing?.createdAt ?? at,
            updatedAt: at,
            dirty: const Value(true),
          ),
        );
  }

  /// Deletes the deck and its cards (the server deletes the cards too, §13.9).
  Future<void> deleteDeck(String id) async {
    final at = now();
    await db.transaction(() async {
      await (db.update(db.localDecks)..where((t) => t.id.equals(id))).write(
        LocalDecksCompanion(deletedAt: Value(at), updatedAt: Value(at), dirty: const Value(true)),
      );
      await (db.update(db.localCards)..where((t) => t.deckId.equals(id) & t.deletedAt.isNull())).write(
        LocalCardsCompanion(deletedAt: Value(at), updatedAt: Value(at), dirty: const Value(true)),
      );
    });
  }

  /// A custom card. Picked images stay local until the sync uploads them. Passing `null` for an
  /// image keeps the current one; [removeFrontImage]/[removeBackImage] clear it.
  Future<void> saveCustomCard({
    required String id,
    required String deckId,
    String? frontText,
    String? backText,
    Uint8List? frontImage,
    Uint8List? backImage,
    bool removeFrontImage = false,
    bool removeBackImage = false,
  }) async {
    final existing = await card(id);
    final at = now();
    String? clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
    await db
        .into(db.localCards)
        .insertOnConflictUpdate(
          LocalCardsCompanion.insert(
            id: id,
            deckId: deckId,
            kind: UserCardKind.custom.json!,
            frontText: Value(clean(frontText)),
            backText: Value(clean(backText)),
            frontMediaId: Value(frontImage != null || removeFrontImage ? null : existing?.frontMediaId),
            backMediaId: Value(backImage != null || removeBackImage ? null : existing?.backMediaId),
            frontImageJson: Value(frontImage != null || removeFrontImage ? null : existing?.frontImageJson),
            backImageJson: Value(backImage != null || removeBackImage ? null : existing?.backImageJson),
            frontLocalImage: Value(frontImage ?? (removeFrontImage ? null : existing?.frontLocalImage)),
            backLocalImage: Value(backImage ?? (removeBackImage ? null : existing?.backLocalImage)),
            sortOrder: existing?.sortOrder ?? (await cards(deckId)).length,
            createdAt: existing?.createdAt ?? at,
            updatedAt: at,
            dirty: const Value(true),
          ),
        );
  }

  /// "أضف إلى بطاقاتي": a reference to an official card, shown with its images (spec §13.9).
  Future<void> addOfficialRef({required String id, required String deckId, required StudentCard official}) async {
    final at = now();
    await db
        .into(db.localCards)
        .insert(
          LocalCardsCompanion.insert(
            id: id,
            deckId: deckId,
            kind: UserCardKind.officialRef.json!,
            officialFlashcardId: Value(official.id),
            frontImageJson: Value(StudyCard.imageToJson(official.front)),
            backImageJson: Value(StudyCard.imageToJson(official.back)),
            sortOrder: (await cards(deckId)).length,
            createdAt: at,
            updatedAt: at,
          ),
        );
  }

  Future<void> deleteCard(String id) {
    final at = now();
    return (db.update(db.localCards)..where((t) => t.id.equals(id))).write(
      LocalCardsCompanion(deletedAt: Value(at), updatedAt: Value(at), dirty: const Value(true)),
    );
  }

  // ---- sync support ----

  Future<List<LocalDeckRow>> dirtyDecks({int limit = 100}) =>
      (db.select(db.localDecks)
            ..where((t) => t.dirty.equals(true))
            ..limit(limit))
          .get();

  /// Dirty cards whose images are uploaded (cards still waiting for an upload stay back).
  Future<List<LocalCardRow>> dirtyCards({int limit = 500}) =>
      (db.select(db.localCards)
            ..where(
              (t) =>
                  t.dirty.equals(true) &
                  (t.deletedAt.isNotNull() |
                      ((t.frontLocalImage.isNull() | t.frontMediaId.isNotNull()) &
                          (t.backLocalImage.isNull() | t.backMediaId.isNotNull()))),
            )
            ..limit(limit))
          .get();

  /// Live cards with a picked image not uploaded yet.
  Future<List<LocalCardRow>> pendingUploads() =>
      (db.select(db.localCards)..where(
            (t) =>
                t.deletedAt.isNull() &
                ((t.frontLocalImage.isNotNull() & t.frontMediaId.isNull()) |
                    (t.backLocalImage.isNotNull() & t.backMediaId.isNull())),
          ))
          .get();

  /// Records an uploaded image without touching `updated_at` (the edit already happened).
  Future<void> setMediaId(String cardId, {required bool front, required String mediaId}) =>
      (db.update(db.localCards)..where((t) => t.id.equals(cardId))).write(
        front ? LocalCardsCompanion(frontMediaId: Value(mediaId)) : LocalCardsCompanion(backMediaId: Value(mediaId)),
      );

  /// Marks pushed rows clean unless they changed again while the request was in flight.
  Future<void> markClean(List<LocalDeckRow> decks, List<LocalCardRow> cards) => db.transaction(() async {
    for (final d in decks) {
      await (db.update(db.localDecks)..where((t) => t.id.equals(d.id) & t.updatedAt.equals(d.updatedAt))).write(
        const LocalDecksCompanion(dirty: Value(false)),
      );
    }
    for (final c in cards) {
      await (db.update(db.localCards)..where((t) => t.id.equals(c.id) & t.updatedAt.equals(c.updatedAt))).write(
        const LocalCardsCompanion(dirty: Value(false)),
      );
    }
  });

  /// Drops local rows the server refused.
  Future<void> discard({Iterable<String> deckIds = const [], Iterable<String> cardIds = const []}) =>
      db.transaction(() async {
        if (deckIds.isNotEmpty) {
          await (db.delete(db.localCards)..where((t) => t.deckId.isIn(deckIds.toList()))).go();
          await (db.delete(db.localDecks)..where((t) => t.id.isIn(deckIds.toList()))).go();
        }
        if (cardIds.isNotEmpty) await (db.delete(db.localCards)..where((t) => t.id.isIn(cardIds.toList()))).go();
      });

  /// Applies the server's feed: a server row replaces the local one unless the local row has a newer
  /// unsynced edit (last write wins, §13.9).
  Future<void> applyServer(UserContentChanges changes) => db.transaction(() async {
    for (final d in changes.decks) {
      final local = await deck(d.id);
      if (local != null && local.dirty && local.updatedAt > _ms(d.updatedAt)) continue;
      await db
          .into(db.localDecks)
          .insertOnConflictUpdate(
            LocalDecksCompanion.insert(
              id: d.id,
              name: d.name,
              subjectId: Value(d.subjectId),
              color: Value(d.color),
              sortOrder: d.sortOrder,
              createdAt: _ms(d.createdAt),
              updatedAt: _ms(d.updatedAt),
              deletedAt: Value(_msOrNull(d.deletedAt)),
              dirty: const Value(false),
            ),
          );
    }
    for (final c in changes.cards) {
      final local = await card(c.id);
      if (local != null && local.dirty && local.updatedAt > _ms(c.updatedAt)) continue;
      // Keep the picked bytes until the server's processed image exists for the same upload.
      Uint8List? keep(Uint8List? bytes, String? localMedia, UserCardFace face) =>
          face.image == null && localMedia != null && localMedia == face.mediaId ? bytes : null;
      final official = c.kind == UserCardKind.officialRef;
      await db
          .into(db.localCards)
          .insertOnConflictUpdate(
            LocalCardsCompanion.insert(
              id: c.id,
              deckId: c.deckId,
              kind: c.kind.json!,
              officialFlashcardId: Value(c.officialFlashcardId),
              frontText: Value(c.front.text),
              backText: Value(c.back.text),
              frontMediaId: Value(c.front.mediaId),
              backMediaId: Value(c.back.mediaId),
              // A locked official card keeps its last images locally but is not shown (§12.5).
              frontImageJson: Value(StudyCard.imageToJson(c.front.image) ?? (official ? local?.frontImageJson : null)),
              backImageJson: Value(StudyCard.imageToJson(c.back.image) ?? (official ? local?.backImageJson : null)),
              frontLocalImage: Value(keep(local?.frontLocalImage, local?.frontMediaId, c.front)),
              backLocalImage: Value(keep(local?.backLocalImage, local?.backMediaId, c.back)),
              locked: Value(c.locked),
              sortOrder: c.sortOrder,
              createdAt: _ms(c.createdAt),
              updatedAt: _ms(c.updatedAt),
              deletedAt: Value(_msOrNull(c.deletedAt)),
              dirty: const Value(false),
            ),
          );
    }
  });

  Future<String?> cursor() => db.getValue(cursorKey);
  Future<void> setCursor(String? cursor) => cursor == null
      ? (db.delete(db.keyValues)..where((t) => t.key.equals(cursorKey))).go()
      : db.setValue(cursorKey, cursor);
}
