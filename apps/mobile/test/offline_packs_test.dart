import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/core/api/api_client.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/core/auth/token_store.dart';
import 'package:plengo/core/db/app_database.dart';
import 'package:plengo/core/offline/local_learning.dart';
import 'package:plengo/core/offline/offline_content.dart';
import 'package:plengo/core/offline/offline_repositories.dart';
import 'package:plengo/core/offline/pack_downloader.dart';
import 'package:plengo/core/offline/pack_files.dart';
import 'package:plengo/core/offline/pack_store.dart';
import 'package:plengo/features/reports/report_sheet.dart';

import 'api_client_test.dart' show ok;

const subject = '11111111-1111-4111-8111-111111111111';
const unit = '22222222-2222-4222-8222-222222222222';
const deckKey = 'subject:$subject:-:deck.d1';
const questionsKey = 'subject:$subject:$unit:questions';
final t0 = DateTime.utc(2026, 9, 28, 9).millisecondsSinceEpoch;

/// A scripted server for pack downloads (spec §22.10). Items and versions can change between calls.
class PackServer implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  final items = <String, Map<String, Object?>>{}; // id -> item json (with version)
  final packs = <String, List<String>>{};
  var premium = false;
  var normalizationVersion = 1;
  Map<String, Object?> Function(RequestOptions o)? leases;
  Map<String, Object?> Function(RequestOptions o)? sync;
  bool offline = false;
  final reports = <Map<String, Object?>>[];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    calls.add(o);
    if (offline) throw DioException.connectionError(requestOptions: o, reason: 'offline');
    Object? json;
    final path = o.uri.path;
    if (o.uri.host == 'cdn.test') {
      return ResponseBody.fromBytes(utf8.encode('image:${o.uri.pathSegments.last}'), 200);
    }
    if (path.endsWith('/manifest')) {
      final key = Uri.decodeComponent(path.split('/packs/')[1].replaceAll('/manifest', ''));
      final ids = packs[key]!;
      json = ok({
        'packKey': key,
        'version': ids.map((id) => '$id@${items[id]!['version']}').join(','),
        'premium': premium,
        'normalizationVersion': normalizationVersion,
        'items': [
          for (final id in ids) {'type': items[id]!['type'], 'id': id, 'version': items[id]!['version']},
        ],
      });
    } else if (path.endsWith('/items')) {
      final key = Uri.decodeComponent(path.split('/packs/')[1].replaceAll('/items', ''));
      final wanted = (o.queryParameters['ids'] as String?)?.split(',').toSet();
      json = ok({
        'items': [
          for (final id in packs[key]!)
            if (wanted == null || wanted.contains(id)) items[id],
        ],
        'nextCursor': null,
        'urlsExpireAt': '2026-09-28T10:00:00Z',
      });
    } else if (path.endsWith('/licenses/refresh')) {
      json = leases!(o);
    } else if (path.endsWith('/offline/sync')) {
      json = sync!(o);
    } else if (path == '/api/v1/reports') {
      reports.add(jsonDecode(jsonEncode(o.data)) as Map<String, Object?>);
      json = ok({
        'id': 'r${reports.length}',
        'itemType': 'question',
        'itemId': 'q1',
        'reason': 'typo',
        'note': null,
        'status': 'open',
        'createdAt': '',
        'resolvedAt': null,
      });
    } else {
      json = {
        'success': false,
        'data': null,
        'error': {'code': 'NOT_FOUND', 'message': 'x'},
      };
    }
    return ResponseBody.fromString(
      jsonEncode(json),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> image(String id, {int version = 1}) => {
  'mediaId': id,
  'version': version,
  'url': 'https://cdn.test/$id-$version',
  'width': 10,
  'height': 10,
  'sizeBytes': 1000,
};

Map<String, Object?> deckItem({bool free = false, List<String> cards = const ['c1', 'c2'], int version = 1}) => {
  'type': 'deck',
  'id': 'd1',
  'version': version,
  'question': null,
  'card': null,
  'quiz': null,
  'deck': {
    'id': 'd1',
    'subjectId': subject,
    'teacherTrackId': null,
    'unitId': unit,
    'lessonId': null,
    'titleAr': 'رموز العناصر',
    'description': null,
    'isFree': free,
    'sortOrder': 0,
    'cardIds': cards,
  },
};

Map<String, Object?> cardItem(String id, {int version = 1}) => {
  'type': 'card',
  'id': id,
  'version': version,
  'question': null,
  'deck': null,
  'quiz': null,
  'card': {'id': id, 'deckId': 'd1', 'sortOrder': 0, 'front': image('$id-f', version: version), 'back': image('$id-b')},
};

Map<String, Object?> questionItem(
  String id, {
  String type = 'mcq',
  bool free = true,
  List<String> accepted = const [],
  int version = 1,
}) => {
  'type': 'question',
  'id': id,
  'version': version,
  'deck': null,
  'card': null,
  'quiz': null,
  'question': {
    'id': id,
    'type': type,
    'subjectId': subject,
    'teacherTrackId': null,
    'unitId': unit,
    'lessonId': null,
    'sortOrder': 0,
    'difficulty': null,
    'isFree': free,
    'questionText': 'سؤال $id',
    'explanation': 'شرح',
    'options': type == 'written'
        ? <Object?>[]
        : [
            {'id': '$id-ok', 'text': 'صحيح', 'isCorrect': true},
            {'id': '$id-no', 'text': 'خطأ', 'isCorrect': false},
          ],
    'acceptedAnswers': [
      for (final a in accepted) {'original': a, 'normalized': a, 'normalizationVersion': 1},
    ],
  },
};

OfflinePack packOf(String key, {String kind = 'deck', bool premium = false, String? deckId = 'd1'}) => OfflinePack(
  packKey: key,
  kind: OfflinePackKind.values.firstWhere((k) => k.json == kind),
  unitId: kind == 'deck' ? null : unit,
  deckId: kind == 'deck' ? deckId : null,
  titleAr: 'حزمة',
  itemCount: 3,
  sizeBytes: 3000,
  version: 'v',
  premium: premium,
);

const scope = OfflineScope(scopeType: OfflineScopeScopeType.subject, subjectId: subject, teacherTrackId: null);

void main() {
  late AppDatabase db;
  late PackStore store;
  late MemoryPackFiles files;
  late PackServer server;
  late ApiClient client;
  late int now;
  late bool wifi;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = PackStore(db);
    files = MemoryPackFiles();
    server = PackServer();
    client = ApiClient(
      baseUrl: 'http://api.test',
      tokens: MemoryTokenStore(),
      platform: 'android',
      appVersion: '1.0.0',
      useCookies: false,
      adapter: server,
    );
    now = t0;
    wifi = true;
  });
  tearDown(() => db.close());

  PackDownloader downloader() =>
      PackDownloader(client: client, store: store, files: files, onWifi: () async => wifi, clock: () => now);
  LeaseManager leases() => LeaseManager(client: client, store: store, files: files, clock: () => now);
  OfflineContent content() => OfflineContent(store: store, leases: leases(), files: files);

  void serveDeck({bool free = true}) {
    server.items
      ..['d1'] = deckItem(free: free)
      ..['c1'] = cardItem('c1')
      ..['c2'] = cardItem('c2');
    server.packs[deckKey] = ['d1', 'c1', 'c2'];
    server.premium = !free;
  }

  Future<void> download(String key, {String kind = 'deck', bool premium = false, bool mobileData = false}) async {
    final d = downloader();
    await d.enqueue(
      packOf(key, kind: kind, premium: premium),
      scope: scope,
      scopeTitle: 'الكيمياء',
    );
    await d.download(key, allowMobileData: mobileData);
  }

  group('downloads (§22.2, §22.3)', () {
    test('a downloaded deck works without the network: cards and encrypted images come from the device', () async {
      serveDeck();
      await download(deckKey);
      expect((await store.pack(deckKey))!.status, 'ready');
      expect(files.files, hasLength(4)); // front and back of two cards
      server.offline = true;
      final c = content();
      expect((await c.cards('d1'))!.map((x) => x.id), ['c1', 'c2']);
      expect(utf8.decode((await c.image('c1-f'))!), 'image:c1-f-1');
      final repo = OfflineFlashcardRepository(client, c);
      final study = await repo.localStudyCards('d1');
      expect(study!.first.front.localImage, isNotNull);
      // Deck metadata and cards fall back to the device offline.
      expect((await repo.deck('d1')).titleAr, 'رموز العناصر');
      expect((await repo.deckCards('d1')).cards, hasLength(2));
    });

    test('an update downloads only changed items and removes deleted ones', () async {
      serveDeck();
      await download(deckKey);
      server.calls.clear();
      server.items['c1'] = cardItem('c1', version: 2);
      server.items['d1'] = deckItem(free: true, cards: ['c1'], version: 2);
      server.packs[deckKey] = ['d1', 'c1'];
      await downloader().download(deckKey);
      final itemCalls = server.calls.where((o) => o.uri.path.endsWith('/items')).toList();
      expect(itemCalls.single.queryParameters['ids'], 'd1,c1');
      expect(server.calls.where((o) => o.uri.host == 'cdn.test').map((o) => o.uri.path), ['/c1-f-2']);
      expect((await store.itemsOf(deckKey)).keys, unorderedEquals(['d1', 'c1']));
      expect(files.files.keys.any((k) => k.contains('c2')), isFalse);
    });

    test('waits for Wi-Fi unless mobile data is allowed', () async {
      serveDeck();
      wifi = false;
      await expectLater(download(deckKey), throwsA(isA<DownloadStopped>()));
      expect((await store.pack(deckKey))!.status, 'waiting_wifi');
      expect(server.calls, isEmpty);
      await downloader().download(deckKey, allowMobileData: true);
      expect((await store.pack(deckKey))!.status, 'ready');
      await store.setWifiOnly(false);
      wifi = false;
      await downloader().download(deckKey); // setting off: no Wi-Fi needed
    });

    test('an interrupted download resumes with only the missing items', () async {
      for (var i = 0; i < 120; i++) {
        server.items['q$i'] = questionItem('q$i');
      }
      server.packs[questionsKey] = [for (var i = 0; i < 120; i++) 'q$i'];
      await downloader().enqueue(
        packOf(questionsKey, kind: 'questions'),
        scope: scope,
        scopeTitle: 'الكيمياء',
      );
      // Paused after the first chunk of 50.
      late final PackDownloader first;
      first = PackDownloader(
        client: client,
        store: store,
        files: files,
        onWifi: () async => true,
        clock: () => now,
        onProgress: (key) => first.pause(key),
      );
      await expectLater(first.download(questionsKey), throwsA(isA<DownloadStopped>()));
      expect((await store.pack(questionsKey))!.status, 'paused');
      expect((await store.itemsOf(questionsKey)).length, 50);
      server.calls.clear();
      await downloader().download(questionsKey);
      expect((await store.itemsOf(questionsKey)).length, 120);
      // Nothing already stored was fetched again.
      final fetched = server.calls
          .where((o) => o.uri.path.endsWith('/items'))
          .expand((o) => (o.queryParameters['ids'] as String).split(','))
          .toList();
      expect(fetched.toSet().length, fetched.length);
    });

    test('cancelling removes the pack and its files', () async {
      serveDeck();
      await download(deckKey);
      await downloader().cancel(deckKey);
      expect(await store.pack(deckKey), isNull);
      expect(files.files, isEmpty);
    });
  });

  group('leases (§22.4)', () {
    Future<void> premiumDeck() async {
      serveDeck(free: false);
      await download(deckKey, premium: true);
    }

    Map<String, Object?> leaseReply(String status, {int? expires}) => ok({
      'serverTime': DateTime.fromMillisecondsSinceEpoch(now, isUtc: true).toIso8601String(),
      'leases': [
        {
          'scopeType': 'subject',
          'subjectId': subject,
          'teacherTrackId': null,
          'status': status,
          'expiresAt': expires == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(expires, isUtc: true).toIso8601String(),
        },
      ],
    });

    test('premium pack content needs a valid lease; free content never does', () async {
      await premiumDeck();
      server.items['q1'] = questionItem('q1');
      server.packs[questionsKey] = ['q1'];
      await download(questionsKey, kind: 'questions');
      final c = content();
      expect(await c.cards('d1'), isNull); // no lease yet
      expect(await c.question('q1'), isNotNull); // free

      server.leases = (_) => leaseReply('active', expires: now + 30 * 86400000);
      expect(await leases().refresh(), isEmpty);
      expect(await c.cards('d1'), hasLength(2));

      // 30 days offline: expired, hidden.
      now += 31 * 86400000;
      expect(await c.cards('d1'), isNull);
      expect(await c.question('q1'), isNotNull);
    });

    test('a device clock set backwards counts as expired', () async {
      await premiumDeck();
      server.leases = (_) => leaseReply('active', expires: now + 30 * 86400000);
      await leases().refresh();
      expect(await content().cards('d1'), hasLength(2));
      now -= 2 * 86400000;
      expect(await content().cards('d1'), isNull);
    });

    test('refreshes at most daily, and a revoked entitlement deletes the premium pack data', () async {
      await premiumDeck();
      var calls = 0;
      server.leases = (_) {
        calls++;
        return leaseReply('active', expires: now + 30 * 86400000);
      };
      await leases().refresh();
      await leases().refresh();
      expect(calls, 1);
      now += 86400000;
      server.leases = (_) => leaseReply('none');
      expect(await leases().refresh(), ['subject:$subject']);
      expect(await store.pack(deckKey), isNull);
      expect(files.files, isEmpty);
      expect(await store.lease('subject:$subject'), isNull);
    });
  });

  group('local grading and sync (§22.6)', () {
    late LocalAttemptStore local;
    setUp(() => local = LocalAttemptStore(db));

    Future<OfflineLearningRepository> withQuiz({int normalizationVersion = 1}) async {
      server.normalizationVersion = normalizationVersion;
      server.items
        ..['q1'] = questionItem('q1')
        ..['q2'] = questionItem('q2', type: 'written', accepted: ['دمشق'])
        ..['z1'] = {
          'type': 'quiz',
          'id': 'z1',
          'version': 1,
          'question': null,
          'deck': null,
          'card': null,
          'quiz': {
            'id': 'z1',
            'subjectId': subject,
            'teacherTrackId': null,
            'unitId': unit,
            'lessonId': null,
            'titleAr': 'اختبار الوحدة',
            'description': null,
            'allowedModes': 'both',
            'timeLimitSeconds': null,
            'passingScore': 50,
            'shuffleQuestions': false,
            'shuffleOptions': false,
            'isFree': true,
            'questionIds': ['q1', 'q2'],
          },
        };
      server.packs[questionsKey] = ['q1', 'q2'];
      server.packs['subject:$subject:$unit:quizzes'] = ['z1'];
      await download(questionsKey, kind: 'questions');
      await download('subject:$subject:$unit:quizzes', kind: 'quizzes');
      return OfflineLearningRepository(client, content: content(), local: local, clock: () => now);
    }

    StartAttemptRequest start(String id, {StartAttemptRequestSource source = StartAttemptRequestSource.curated}) =>
        StartAttemptRequest(
          clientAttemptId: id,
          source: source,
          mode: StartAttemptRequestMode.practice,
          quizId: source == StartAttemptRequestSource.curated ? 'z1' : null,
          filters: source == StartAttemptRequestSource.random ? const AttemptFilters(subjectId: subject) : null,
        );

    test('a downloaded quiz runs on the device, grades instantly and syncs once', () async {
      final repo = await withQuiz();
      server.offline = true;
      final a = await repo.start(start('aaaaaaaa-0000-4000-8000-000000000001'));
      expect(a.attempt.id, startsWith(localAttemptPrefix));
      expect(a.questions.first.options.every((o) => o.isCorrect == null), isTrue); // not revealed yet

      final wrong = await repo.check(a.attempt.id, 'q1', const CheckAttemptAnswerRequest(selectedOptionId: 'q1-no'));
      expect(wrong.isCorrect, isFalse);
      expect(wrong.correctOptionId, 'q1-ok');
      // Alef, diacritics and spaces normalize like the server's grader.
      final written = await repo.check(
        a.attempt.id,
        'q2',
        const CheckAttemptAnswerRequest(writtenAnswer: '  دِمَشْق '),
      );
      expect(written.isCorrect, isTrue);
      expect(await local.mistakeIds(), ['q1']); // the local mistakes mirror

      final done = await repo.submit(a.attempt.id, const SubmitAttemptRequest(answers: []));
      expect(done.attempt.correctCount, 1);
      expect(done.attempt.passed, isTrue);
      expect((await repo.attempt(a.attempt.id)).attempt.status, AttemptStatus.submitted);
      // Offline history shows it.
      expect((await repo.attempts(quizId: 'z1')).items.single.id, a.attempt.id);

      server.offline = false;
      Map<String, Object?>? sent;
      server.sync = (o) {
        sent = jsonDecode(jsonEncode(o.data)) as Map<String, Object?>;
        return ok({
          'results': [
            {
              'clientAttemptId': 'aaaaaaaa-0000-4000-8000-000000000001',
              'status': 'accepted',
              'reason': null,
              'attemptId': 'server-1',
              'correctCount': 1,
              'totalCount': 2,
              'mismatches': 0,
            },
          ],
        });
      };
      final sync = OfflineAttemptSync(client: client, local: local);
      expect(await sync.push(), 1);
      final payload = (sent!['attempts']! as List).single as Map;
      expect(payload['quizId'], 'z1');
      expect(payload['answers'], [
        {'questionId': 'q1', 'selectedOptionId': 'q1-no', 'flagged': false, 'localIsCorrect': false},
        {'questionId': 'q2', 'writtenAnswer': '  دِمَشْق ', 'flagged': false, 'localIsCorrect': true},
      ]);
      expect(await local.mistakeIds(), isEmpty); // the server's mistake bank takes over
      expect(await sync.push(), 0); // nothing left: the same attempt is never sent twice
    });

    test('random practice is built from pack questions when the server is unreachable', () async {
      final repo = await withQuiz();
      server.offline = true;
      final a = await repo.start(
        start('aaaaaaaa-0000-4000-8000-000000000002', source: StartAttemptRequestSource.random),
      );
      expect(a.attempt.source, AttemptSummarySource.random);
      expect(a.questions.map((q) => q.questionId), unorderedEquals(['q1', 'q2']));
    });

    test('a pack from another normalizer version sends written questions to the server', () async {
      final repo = await withQuiz(normalizationVersion: 2);
      server.offline = true;
      await expectLater(
        repo.start(start('aaaaaaaa-0000-4000-8000-000000000003')),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );
      final questions = OfflineQuestionRepository(client, content());
      // The multiple-choice question still grades on the device.
      expect((await questions.check('q1', selectedOptionId: 'q1-ok')).isCorrect, isTrue);
    });
  });

  test('content reports written offline are queued and sent later (§22.7)', () async {
    final repo = ReportRepository(client.api, db);
    server.offline = true;
    expect(await repo.create(ReportItemType.question, 'q1', ReportReason.typo, 'خطأ'), isNull);
    expect(await repo.create(ReportItemType.question, 'q2', ReportReason.unclear, null), isNull);
    expect(await repo.flush(), 0); // still offline: kept
    server.offline = false;
    expect(await repo.flush(), 2);
    expect(server.reports.map((r) => r['itemId']), ['q1', 'q2']);
    expect(await repo.flush(), 0); // sent once
    // Online, a report goes straight to the server.
    expect((await repo.create(ReportItemType.question, 'q3', ReportReason.other, null))!.id, 'r3');
  });

  test('logout wipes pack tables (files are deleted by the controller)', () async {
    serveDeck();
    await download(deckKey);
    await db.wipe();
    expect(await store.packs(), isEmpty);
    expect(await store.itemsOf(deckKey), isEmpty);
    await files.deleteAll();
    expect(files.files, isEmpty);
    // Settings survive logout.
    await store.setWifiOnly(false);
    await db.wipe();
    expect(await store.wifiOnly(), isFalse);
    await db
        .into(db.offlineLeaseRows)
        .insert(OfflineLeaseRowsCompanion.insert(scopeKey: 'x', expiresAt: 1, refreshedAt: 1));
    await db.wipe();
    expect(await store.leases(), isEmpty);
    expect(const Value(1).value, 1);
  });
}
