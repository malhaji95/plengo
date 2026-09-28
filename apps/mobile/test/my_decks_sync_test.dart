import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/core/api/api_client.dart';
import 'package:plengo/core/auth/token_store.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/core/content/flashcard_repository.dart';
import 'package:plengo/core/content/media_uploader.dart';
import 'package:plengo/core/content/my_decks_repository.dart';
import 'package:plengo/core/content/my_decks_store.dart';
import 'package:plengo/core/db/app_database.dart';
import 'package:plengo/core/srs/scheduler.dart';
import 'package:plengo/core/srs/srs_key.dart';
import 'package:plengo/core/srs/srs_store.dart';

import 'api_client_test.dart' show FakeAdapter, ok;

/// Student decks sync (spec §13.9) through the real store, repository and HTTP client, against a
/// scripted server.
void main() {
  final t0 = DateTime.utc(2026, 9, 28, 9).millisecondsSinceEpoch;
  late AppDatabase db;
  late MyDecksStore store;
  late int now;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    now = t0;
    store = MyDecksStore(db, clock: () => now);
  });
  tearDown(() => db.close());

  ApiClient clientWith(FakeAdapter adapter) => ApiClient(
    baseUrl: 'http://api.test',
    tokens: MemoryTokenStore(),
    platform: 'android',
    appVersion: '1.0.0',
    useCookies: false,
    adapter: adapter,
  );

  Map<String, Object?> body(Object? data) => jsonDecode(jsonEncode(data)) as Map<String, Object?>;
  Map<String, Object?> syncResult({int decks = 0, int cards = 0, List<Object?> rejected = const []}) => {
    'appliedDecks': decks,
    'appliedCards': cards,
    'rejected': rejected,
  };

  test('pushes offline edits with UTC times, then marks them clean', () async {
    await store.saveDeck(id: 'd1', name: ' مفرداتي ', color: '#1E88E5');
    now += 1000;
    await store.saveCustomCard(id: 'c1', deckId: 'd1', frontText: 'سؤال', backText: 'جواب');
    Map<String, Object?>? sent;
    final adapter = FakeAdapter((o) async {
      sent = body(o.data);
      return (200, ok(syncResult(decks: 1, cards: 1)));
    });
    final report = await MyDecksRepository(clientWith(adapter)).push(store);
    expect(report.pushed, 2);
    expect(adapter.calls.single.path, '/api/v1/my-decks/sync');
    final deck = (sent!['decks']! as List).single as Map;
    expect(deck, containsPair('name', 'مفرداتي'));
    expect(deck['createdAt'], DateTime.fromMillisecondsSinceEpoch(t0, isUtc: true).toIso8601String());
    expect((deck['updatedAt'] as String).endsWith('Z'), isTrue);
    final card = (sent!['cards']! as List).single as Map;
    expect(card, allOf(containsPair('kind', 'custom'), containsPair('frontText', 'سؤال')));
    expect(card.containsKey('frontMediaId'), isFalse); // unset optional fields are omitted
    expect(await store.dirtyDecks(), isEmpty);
    expect(await store.dirtyCards(), isEmpty);
    // Nothing left: no request.
    await MyDecksRepository(clientWith(adapter)).push(store);
    expect(adapter.calls, hasLength(1));
  });

  test('an edit made while the push was in flight stays dirty', () async {
    await store.saveDeck(id: 'd1', name: 'أ');
    final adapter = FakeAdapter((o) async {
      now += 1000;
      await store.saveDeck(id: 'd1', name: 'ب');
      return (200, ok(syncResult(decks: 1)));
    });
    await MyDecksRepository(clientWith(adapter)).push(store);
    expect((await store.dirtyDecks()).single.name, 'ب');
  });

  test('uploads picked images first, then sends the card with the media id', () async {
    await store.saveDeck(id: 'd1', name: 'صور');
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4]);
    await store.saveCustomCard(id: 'c1', deckId: 'd1', frontImage: jpeg, backText: 'جواب');
    final paths = <String>[];
    Map<String, Object?>? created;
    Map<String, Object?>? synced;
    final adapter = FakeAdapter((o) async {
      paths.add('${o.method} ${o.uri}');
      if (o.path == '/api/v1/uploads') {
        created = body(o.data);
        return (
          200,
          ok({
            'id': 'm1',
            'uploadUrl': 'https://storage.test/put/m1?sig=x',
            'method': 'PUT',
            'headers': {'content-type': 'image/jpeg'},
            'expiresAt': '2026-09-28T09:15:00Z',
          }),
        );
      }
      if (o.path == '/api/v1/uploads/m1/complete') {
        return (
          200,
          ok({'id': 'm1', 'kind': 'user-card', 'status': 'pending', 'width': null, 'height': null, 'version': 1}),
        );
      }
      if (o.path == '/api/v1/my-decks/sync') {
        synced = body(o.data);
        return (200, ok(syncResult(decks: 1, cards: 1)));
      }
      return (200, ok(<String, Object?>{})); // the storage PUT
    });
    await MyDecksRepository(clientWith(adapter)).push(store);
    expect(paths, [
      'POST http://api.test/api/v1/uploads',
      'PUT https://storage.test/put/m1?sig=x',
      'POST http://api.test/api/v1/uploads/m1/complete',
      'POST http://api.test/api/v1/my-decks/sync',
    ]);
    expect(created, {'kind': 'user-card', 'contentType': 'image/jpeg', 'size': 8});
    // The storage request carries no API credentials or app headers.
    final put = adapter.calls[1];
    expect(put.headers.containsKey('authorization'), isFalse);
    expect(put.headers.containsKey('X-App-Platform'), isFalse);
    expect(((synced!['cards']! as List).single as Map)['frontMediaId'], 'm1');
    // The picked bytes stay for display until the processed image arrives.
    expect((await store.card('c1'))!.frontLocalImage, isNotNull);
  });

  test('a card waiting for its image upload is not sent yet', () async {
    await store.saveDeck(id: 'd1', name: 'صور');
    final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0]);
    await store.saveCustomCard(id: 'c1', deckId: 'd1', frontImage: png, backText: 'جواب');
    expect((await store.dirtyCards()).map((c) => c.id), isEmpty);
    expect((await store.pendingUploads()).single.id, 'c1');
  });

  test('refused items are dropped locally and the feed is fetched again', () async {
    await store.setCursor('old');
    await store.saveDeck(id: 'd1', name: 'زائدة');
    await store.saveCustomCard(id: 'c1', deckId: 'd1', frontText: 'أ', backText: 'ب');
    final adapter = FakeAdapter(
      (o) async => (
        200,
        ok(
          syncResult(
            rejected: [
              {'type': 'deck', 'id': 'd1', 'code': 'QUOTA_EXCEEDED', 'reason': 'deck_quota'},
              {'type': 'card', 'id': 'c1', 'code': 'NOT_FOUND', 'reason': 'deck'},
            ],
          ),
        ),
      ),
    );
    final report = await MyDecksRepository(clientWith(adapter)).push(store);
    expect(report.rejected.map((r) => r.reason), ['deck_quota', 'deck']);
    expect(await store.deck('d1'), isNull);
    expect(await store.card('c1'), isNull);
    expect(await store.cursor(), isNull);
  });

  test('pull applies the feed; a newer local edit wins (last write wins)', () async {
    await store.saveDeck(id: 'd1', name: 'محلي', sortOrder: 0);
    Map<String, Object?> deck(String id, String name, int updatedAt, {int? deletedAt}) => {
      'id': id,
      'name': name,
      'subjectId': null,
      'color': null,
      'sortOrder': 0,
      'cardCount': 0,
      'createdAt': DateTime.fromMillisecondsSinceEpoch(t0, isUtc: true).toIso8601String(),
      'updatedAt': DateTime.fromMillisecondsSinceEpoch(updatedAt, isUtc: true).toIso8601String(),
      'deletedAt': deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedAt, isUtc: true).toIso8601String(),
    };
    Map<String, Object?> officialCard(bool locked) => {
      'id': 'c9',
      'deckId': 'd2',
      'kind': 'official_ref',
      'officialFlashcardId': 'f1',
      'locked': locked,
      'front': {
        'text': null,
        'mediaId': null,
        'image': locked
            ? null
            : {'mediaId': 'm9', 'cacheKey': 'm9:1', 'fullUrl': 'u', 'thumbUrl': 't', 'width': 10, 'height': 10},
      },
      'back': {'text': null, 'mediaId': null, 'image': null},
      'sortOrder': 0,
      'createdAt': '2026-09-28T09:00:00.000Z',
      'updatedAt': '2026-09-28T09:00:00.000Z',
      'deletedAt': null,
    };
    var page = 0;
    final adapter = FakeAdapter((o) async {
      page++;
      expect(o.queryParameters['since'], page == 1 ? null : 'cur1');
      return (
        200,
        ok(
          page == 1
              ? {
                  'decks': [deck('d1', 'قديم من الخادم', t0 - 5000), deck('d2', 'من جهاز آخر', t0 - 5000)],
                  'cards': [officialCard(false)],
                  'cursor': 'cur1',
                  'hasMore': true,
                  'urlsExpireAt': '',
                }
              : {
                  'decks': [deck('d3', 'محذوفة', t0, deletedAt: t0)],
                  'cards': [officialCard(true)],
                  'cursor': 'cur2',
                  'hasMore': false,
                  'urlsExpireAt': '',
                },
        ),
      );
    });
    await MyDecksRepository(clientWith(adapter)).pull(store);
    expect(await store.cursor(), 'cur2');
    final decks = {for (final d in await store.decks()) d.deck.id: d.deck.name};
    expect(decks, {'d1': 'محلي', 'd2': 'من جهاز آخر'}); // d3 is deleted
    // A card whose official source became locked keeps its images but is marked locked.
    final c9 = (await store.card('c9'))!;
    expect(c9.locked, isTrue);
    expect(c9.frontImageJson, contains('m9'));
  });

  group('reviews of student cards', () {
    late SrsStore srs;
    setUp(() => srs = SrsStore(db));

    Future<void> review(String key, String logId) async {
      final before = CardState.newCard(t0);
      final after = schedule(before, Rating.good, t0, key);
      await srs.putState(key, after);
      await srs.addLog(
        LocalReviewLog(id: logId, flashcardId: key, rating: Rating.good, before: before, after: after, reviewedAt: t0),
      );
    }

    test('are sent with userCardId; unknown cards wait, missing ones are dropped', () async {
      await review(SrsKey.userCard('u1'), 'l1'); // synced card
      await review(SrsKey.userCard('u2'), 'l2'); // not on the server yet
      await review(SrsKey.userCard('gone'), 'l3'); // refused and removed
      await review('official-1', 'l4');
      Map<String, Object?>? sent;
      final adapter = FakeAdapter((o) async {
        sent = body(o.data);
        return (200, ok({'acceptedLogs': 2, 'appliedStates': 2, 'states': <Object?>[]}));
      });
      Future<bool?> ready(String key) async => switch (SrsKey.idOf(key)) {
        'u2' => false,
        'gone' => null,
        _ => true,
      };
      expect(await FlashcardRepository(clientWith(adapter)).push(srs, ready: ready), 2);
      final logs = [for (final l in sent!['logs']! as List) l as Map];
      expect(logs.map((l) => (l['id'], l['userCardId'], l['flashcardId'])), [
        ('l1', 'u1', null),
        ('l4', null, 'official-1'),
      ]);
      final states = [for (final s in sent!['states']! as List) s as Map];
      expect(states.map((s) => s['userCardId'] ?? s['flashcardId']).toSet(), {'u1', 'official-1'});
      // l2 waits for the decks sync; l3 is gone for good.
      expect((await srs.pendingLogs()).map((l) => l.id), ['l2']);
    });
  });

  group('media uploader (§12.3)', () {
    test('accepts PNG, JPEG and WebP by their bytes, nothing else', () {
      expect(sniffImageType(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1, 0])), 'image/jpeg');
      expect(sniffImageType(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0])), 'image/png');
      expect(
        sniffImageType(Uint8List.fromList([...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits, 0])),
        'image/webp',
      );
      expect(sniffImageType(Uint8List.fromList([...'GIF89a'.codeUnits, 0, 0, 0, 0, 0, 0, 0])), isNull);
    });

    test('refuses files over 2 MB before any request', () async {
      final adapter = FakeAdapter((o) async => (200, ok(<String, Object?>{})));
      final big = Uint8List(maxStudentUploadBytes + 1)..setAll(0, [0xFF, 0xD8, 0xFF, 0xE0]);
      await expectLater(
        MediaUploader(clientWith(adapter)).upload(big, MediaKind.avatar),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
      expect(adapter.calls, isEmpty);
    });

    test('waits until the server has processed the image', () async {
      var polls = 0;
      final adapter = FakeAdapter((o) async {
        polls++;
        return (
          200,
          ok({
            'id': 'm1',
            'kind': 'avatar',
            'status': polls < 3 ? 'pending' : 'ready',
            'width': 400,
            'height': 400,
            'version': 1,
          }),
        );
      });
      final media = await MediaUploader(clientWith(adapter)).waitReady('m1', every: Duration.zero);
      expect(media.status, MediaFileStatus.ready);
      expect(polls, 3);
      expect(adapter.calls.first.path, '/api/v1/uploads/m1');
    });
  });
}
