import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';
import '../db/app_database.dart';
import 'media_uploader.dart';
import 'my_decks_store.dart';

DateTime _utc(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

/// What one sync did, for messages ("تجاوزت الحد المسموح") and tests.
class MyDecksSyncReport {
  const MyDecksSyncReport({this.pushed = 0, this.rejected = const [], this.uploadErrors = const []});

  final int pushed;
  final List<SyncRejection> rejected;
  final List<ApiException> uploadErrors;
}

/// Syncs the student's decks with the server (spec §13.9): upload picked images, push dirty rows
/// (last write wins by `updated_at`), drop what the server refused, then pull the changes feed.
class MyDecksRepository {
  MyDecksRepository(this.client) : uploader = MediaUploader(client);

  final ApiClient client;
  final MediaUploader uploader;

  static UserDeckWrite deckWrite(LocalDeckRow d) => UserDeckWrite(
    id: d.id,
    name: d.name,
    subjectId: d.subjectId,
    color: d.color,
    sortOrder: d.sortOrder,
    createdAt: _utc(d.createdAt),
    updatedAt: _utc(d.updatedAt),
    deletedAt: d.deletedAt == null ? null : _utc(d.deletedAt!),
  );

  static UserCardWrite cardWrite(LocalCardRow c) => UserCardWrite(
    id: c.id,
    deckId: c.deckId,
    kind: UserCardKind.values.firstWhere((k) => k.json == c.kind),
    frontText: c.frontText,
    backText: c.backText,
    frontMediaId: c.frontMediaId,
    backMediaId: c.backMediaId,
    officialFlashcardId: c.officialFlashcardId,
    sortOrder: c.sortOrder,
    createdAt: _utc(c.createdAt),
    updatedAt: _utc(c.updatedAt),
    deletedAt: c.deletedAt == null ? null : _utc(c.deletedAt!),
  );

  Future<List<ApiException>> _uploadPending(MyDecksStore store) async {
    final errors = <ApiException>[];
    for (final c in await store.pendingUploads()) {
      for (final front in [true, false]) {
        final bytes = front ? c.frontLocalImage : c.backLocalImage;
        final media = front ? c.frontMediaId : c.backMediaId;
        if (bytes == null || media != null) continue;
        try {
          await store.setMediaId(c.id, front: front, mediaId: await uploader.upload(bytes, MediaKind.userCard));
        } on ApiException catch (e) {
          if (e.code == 'NETWORK_ERROR') rethrow;
          errors.add(e);
        }
      }
    }
    return errors;
  }

  Future<MyDecksSyncReport> push(MyDecksStore store) => guardApi(() async {
    final uploadErrors = await _uploadPending(store);
    final decks = await store.dirtyDecks();
    final cards = await store.dirtyCards();
    if (decks.isEmpty && cards.isEmpty) return MyDecksSyncReport(uploadErrors: uploadErrors);
    final result = (await client.api.myDecks.syncMyDecks(
      body: UserContentSyncRequest(
        decks: [for (final d in decks) deckWrite(d)],
        cards: [for (final c in cards) cardWrite(c)],
      ),
    )).data;
    await store.markClean(decks, cards);
    if (result.rejected.isNotEmpty) {
      await store.discard(
        deckIds: [
          for (final r in result.rejected)
            if (r.type == SyncRejectionType.deck) r.id,
        ],
        cardIds: [
          for (final r in result.rejected)
            if (r.type == SyncRejectionType.card) r.id,
        ],
      );
      // A refused edit of an existing item: fetch the server's copy again.
      await store.setCursor(null);
    }
    return MyDecksSyncReport(
      pushed: decks.length + cards.length,
      rejected: result.rejected,
      uploadErrors: uploadErrors,
    );
  });

  Future<void> pull(MyDecksStore store) => guardApi(() async {
    while (true) {
      final page = (await client.api.myDecks.myDeckChanges(since: await store.cursor())).data;
      await store.applyServer(page);
      await store.setCursor(page.cursor);
      if (!page.hasMore) return;
    }
  });
}
