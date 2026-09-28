import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/core/api/api_client.dart';
import 'package:plengo/core/auth/token_store.dart';
import 'package:plengo/core/content/flashcard_repository.dart';
import 'package:plengo/core/db/app_database.dart';
import 'package:plengo/core/srs/scheduler.dart';
import 'package:plengo/core/srs/srs_store.dart';

import 'api_client_test.dart' show FakeAdapter, ok;

/// Device ↔ server sync of spaced-repetition data (spec §13.6–§13.8) through the real repository,
/// local store and HTTP client, against a scripted server.
void main() {
  final t0 = DateTime.utc(2026, 9, 27, 9).millisecondsSinceEpoch;
  late AppDatabase db;
  late SrsStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = SrsStore(db);
  });
  tearDown(() => db.close());

  FlashcardRepository repoWith(FakeAdapter adapter) => FlashcardRepository(
    ApiClient(
      baseUrl: 'http://api.test',
      tokens: MemoryTokenStore(),
      platform: 'android',
      appVersion: '1.0.0',
      useCookies: false,
      adapter: adapter,
    ),
  );

  Map<String, Object?> serverState(String id, CardState s) => {
    ...s.toJson(),
    'flashcardId': id,
    'updatedAt': DateTime.utc(2026, 9, 27, 10).toIso8601String(),
  };

  Future<LocalReviewLog> review(String card, Rating rating, int at, {String id = 'log-1'}) async {
    final before = (await store.statesFor([card]))[card] ?? CardState.newCard(at);
    final after = schedule(before, rating, at, card);
    await store.putState(card, after);
    final log = LocalReviewLog(id: id, flashcardId: card, rating: rating, before: before, after: after, reviewedAt: at);
    await store.addLog(log);
    return log;
  }

  test('push sends pending logs with current states, marks them synced and adopts server state', () async {
    await review('c1', Rating.good, t0);
    Map<String, Object?>? sent;
    final newer = schedule(schedule(CardState.newCard(t0), Rating.good, t0, 'c1'), Rating.good, t0 + 600000, 'c1');
    final adapter = FakeAdapter((o) async {
      sent = jsonDecode(jsonEncode(o.data)) as Map<String, Object?>; // as sent on the wire
      return (
        200,
        ok({
          'acceptedLogs': 1,
          'appliedStates': 1,
          'states': [serverState('c1', newer)],
        }),
      );
    });
    expect(await repoWith(adapter).push(store), 1);
    expect(adapter.calls.single.path, '/api/v1/srs/sync');
    final logs = sent!['logs']! as List;
    expect((logs.single as Map)['id'], 'log-1');
    expect((logs.single as Map)['rating'], 'good');
    expect(((sent!['states']! as List).single as Map)['flashcardId'], 'c1');
    expect(await store.pendingLogs(), isEmpty);
    // Another device's newer review wins (§13.8).
    expect((await store.statesFor(['c1']))['c1']!.lastReviewedAt, newer.lastReviewedAt);
    // Nothing pending: no request.
    expect(await repoWith(adapter).push(store), 0);
    expect(adapter.calls, hasLength(1));
  });

  test('an older server state never overwrites a newer local review', () async {
    await review('c1', Rating.good, t0 + 1000);
    final local = (await store.statesFor(['c1']))['c1']!;
    await store.mergeServer({'c1': schedule(CardState.newCard(t0), Rating.again, t0, 'c1')});
    expect((await store.statesFor(['c1']))['c1']!.lastReviewedAt, local.lastReviewedAt);
  });

  test('an undone log is sent again, flagged undone', () async {
    final log = await review('c1', Rating.easy, t0);
    final adapter = FakeAdapter((o) async => (200, ok({'acceptedLogs': 1, 'appliedStates': 0, 'states': []})));
    await repoWith(adapter).push(store);
    await store.markUndone(log.id);
    Map<String, Object?>? sent;
    final again = FakeAdapter((o) async {
      sent = jsonDecode(jsonEncode(o.data)) as Map<String, Object?>; // as sent on the wire
      return (200, ok({'acceptedLogs': 0, 'appliedStates': 0, 'states': []}));
    });
    await repoWith(again).push(store);
    expect(((sent!['logs']! as List).single as Map)['undone'], true);
  });

  test('pull pages through changed states and remembers the cursor', () async {
    final page1 = [
      for (var i = 0; i < 500; i++) serverState('p$i', schedule(CardState.newCard(t0), Rating.good, t0, 'p$i')),
    ];
    final page2 = [serverState('last', schedule(CardState.newCard(t0), Rating.easy, t0, 'last'))];
    final adapter = FakeAdapter((o) async {
      final since = o.queryParameters['since'];
      return since == null
          ? (200, ok({'items': page1, 'nextCursor': 'cursor-1'}))
          : (200, ok({'items': page2, 'nextCursor': 'cursor-2'}));
    });
    await repoWith(adapter).pull(store);
    expect(adapter.calls, hasLength(2));
    expect(adapter.calls[1].queryParameters['since'], 'cursor-1');
    expect(await store.cursor(), 'cursor-2');
    expect((await store.statesFor(['p0', 'p499', 'last'])).length, 3);
  });

  test('offline push keeps the logs for later', () async {
    await review('c1', Rating.good, t0);
    final adapter = FakeAdapter((o) async => throw Exception('offline'));
    await expectLater(repoWith(adapter).push(store), throwsA(anything));
    expect(await store.pendingLogs(), hasLength(1));
  });
}
