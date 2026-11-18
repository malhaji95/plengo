import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/core/content/my_decks_repository.dart';
import 'package:plengo/core/content/my_decks_store.dart';
import 'package:plengo/core/db/app_database.dart';
import 'package:plengo/core/srs/scheduler.dart';
import 'package:plengo/core/srs/srs_store.dart';
import 'package:plengo/features/access/redeem_screen.dart';
import 'package:plengo/features/bookmarks/saved_tab.dart';
import 'package:plengo/features/flashcards/browse_screen.dart';
import 'package:plengo/features/flashcards/deck_screen.dart';
import 'package:plengo/features/flashcards/hard_cards.dart';
import 'package:plengo/features/make_cards/card_templates.dart';
import 'package:plengo/features/make_cards/create_group_screen.dart';
import 'package:plengo/features/make_cards/group_screens.dart';
import 'package:plengo/features/make_cards/make_cards_screen.dart';
import 'package:plengo/features/plengo_cards/plengo_cards_screen.dart';

import 'helpers.dart';
import 'home_test.dart' show location;

CardImage image(String id) =>
    CardImage(mediaId: id, cacheKey: '$id:1', fullUrl: 'https://x/$id', thumbUrl: 'https://x/$id', width: 3, height: 2);

StudentCard card(int i, {String deckId = 'd1', bool back = true}) => StudentCard(
  id: 'c$i',
  deckId: deckId,
  sortOrder: i,
  contentVersion: 1,
  front: image('f$i'),
  back: back ? image('b$i') : null,
);

StudentDeck deck(
  String id, {
  String subjectId = 'p',
  String? title,
  bool locked = false,
  bool isFree = false,
  int cardCount = 12,
}) => StudentDeck(
  id: id,
  subjectId: subjectId,
  teacherTrackId: null,
  unitId: null,
  lessonId: null,
  titleAr: title ?? 'مجموعة $id',
  description: null,
  coverUrl: null,
  cardCount: cardCount,
  isFree: isFree,
  locked: locked,
  contentVersion: 1,
  sortOrder: 0,
);

PlengoDeckGroup subjectGroup(String subjectId, String name, int order, List<StudentDeck> decks) => PlengoDeckGroup(
  subjectId: subjectId,
  subjectNameAr: name,
  subjectCode: subjectId,
  subjectCoverUrl: null,
  subjectSortOrder: order,
  decks: decks,
);

DeckCards deckCards(StudentDeck d, List<StudentCard> cards, {bool preview = false}) =>
    DeckCards(deck: d, cards: cards, previewOnly: preview, previewLimit: preview ? 5 : null, urlsExpireAt: '');

final t0 = DateTime.utc(2026, 11, 18, 9).millisecondsSinceEpoch;

void main() {
  setUpAll(() {
    registerFallbacks();
    registerFallbackValue(BookmarkItemType.flashcard);
  });

  void useSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> go(WidgetTester tester, PumpedApp app, String path) async {
    app.container.read(routerProvider).go(path);
    await tester.pumpAndSettle();
  }

  /// Lets the debounced background syncs run (they are mocked) so no timer outlives the test.
  Future<void> flushSync(WidgetTester tester) => tester.pump(const Duration(seconds: 3));

  final plengoList = PlengoDeckList(
    groups: [
      subjectGroup('c', 'الكيمياء', 2, [deck('d3', subjectId: 'c', title: 'قوانين الكيمياء')]),
      subjectGroup('p', 'الفيزياء', 1, [
        deck('d1', title: 'قوانين الفيزياء', locked: true),
        deck('d2', title: 'رسمات العلوم', isFree: true),
      ]),
      subjectGroup('e', 'التاريخ', 3, const []),
    ],
  );

  group('فلاش كاردز بلينغو (v3 §6)', () {
    test('groups follow the subjects order, empty ones are left out, a pill keeps one subject', () {
      expect([for (final g in visibleGroups(plengoList, null)) g.subjectId], ['p', 'c']);
      expect([for (final g in visibleGroups(plengoList, 'c')) g.subjectId], ['c']);
    });

    testWidgets('decks as products grouped by subject; pills filter; a tap opens the deck', (tester) async {
      useSize(tester, const Size(390, 1600));
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeFlashcards: (f) {
          when(
            () => f.plengoDecks(
              subjectId: any(named: 'subjectId'),
              educationLevelId: any(named: 'educationLevelId'),
            ),
          ).thenAnswer((_) async => plengoList);
          when(() => f.deck('d2')).thenAnswer((_) async => deck('d2', title: 'رسمات العلوم', isFree: true));
          when(
            () => f.deckCards('d2'),
          ).thenAnswer((_) async => deckCards(deck('d2', isFree: true), [card(0, deckId: 'd2')]));
        },
      );
      await go(tester, app, Routes.plengoCards);
      expect(find.byType(PlengoCardsScreen), findsOneWidget);
      // No header art bundled: the drawn header.
      expect(find.byKey(const Key('placeHeader.drawn')), findsOneWidget);
      for (final t in ['قوانين الفيزياء', 'رسمات العلوم', 'قوانين الكيمياء']) {
        expect(find.text(t), findsWidgets, reason: t);
      }
      expect(find.text('التاريخ'), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const Key('plengoDeck.d1'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('plengoDeck.d3'))).dy),
      );
      expect(find.descendant(of: find.byKey(const Key('plengoDeck.d1')), matching: find.text('مقفل')), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('plengoDeck.d2')), matching: find.text('مجانية')),
        findsOneWidget,
      );
      expect(find.text('12 بطاقة'), findsNWidgets(3));
      // No cover: a box in the subject's colour with the title.
      expect(find.byKey(const Key('deckCover.fallback')), findsNWidgets(3));

      final pills = find.byKey(const Key('plengoCards.pills'));
      await tester.tap(find.descendant(of: pills, matching: find.text('الكيمياء')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('plengoDeck.d1')), findsNothing);
      expect(find.byKey(const Key('plengoDeck.d3')), findsOneWidget);
      await tester.tap(find.descendant(of: pills, matching: find.text('الكل')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('plengoDeck.d1')), findsOneWidget);

      // ?subjectId= selects that subject.
      await go(tester, app, '${Routes.plengoCards}?subjectId=p');
      expect(find.byKey(const Key('plengoDeck.d3')), findsNothing);
      expect(find.byKey(const Key('plengoDeck.d2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('plengoDeck.d2')));
      await tester.pumpAndSettle();
      expect(find.byType(DeckScreen), findsOneWidget);
      expect(tester.widget<DeckScreen>(find.byType(DeckScreen)).deckId, 'd2');
    });
  });

  group('locked decks: preview then the locked notice (v3 §6)', () {
    final locked = deck('d1', title: 'قوانين الفيزياء', locked: true, cardCount: 40);

    Future<PumpedApp> pump(WidgetTester tester, {bool coupon = true}) async {
      useSize(tester, const Size(390, 1000));
      return pumpApp(
        tester,
        signedInAs: testMe,
        couponRedemption: coupon,
        arrangeFlashcards: (f) {
          when(() => f.deck('d1')).thenAnswer((_) async => locked);
          when(
            () => f.deckCards('d1'),
          ).thenAnswer((_) async => deckCards(locked, [for (var i = 0; i < 5; i++) card(i)], preview: true));
        },
      );
    }

    testWidgets('browse shows the 5 preview cards, then «هذا المحتوى يحتاج إلى تفعيل»', (tester) async {
      final app = await pump(tester);
      await go(tester, app, '/decks/d1');
      expect(find.byKey(const Key('deck.preview')), findsOneWidget);
      expect(find.text('مراجعة'), findsNothing);
      await tester.tap(find.byKey(const Key('deck.preview')));
      await tester.pumpAndSettle();
      expect(find.byType(BrowseScreen), findsOneWidget);
      expect(find.text('1 / 6'), findsOneWidget);
      expect(find.text('img:f0'), findsOneWidget);
      // No «أضف إلى بطاقاتي» on a preview.
      expect(find.byKey(const Key('add-to-my-decks')), findsNothing);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('التالي'));
        await tester.pumpAndSettle();
      }
      expect(find.text('6 / 6'), findsOneWidget);
      expect(find.byKey(const Key('browse.lockedEnd')), findsOneWidget);
      expect(find.text('هذا المحتوى يحتاج إلى تفعيل'), findsOneWidget);
      expect(find.text('اقلب البطاقة'), findsNothing);
      expect(find.byKey(const Key('card.star')), findsNothing);
      await tester.tap(find.text('إدخال كود التفعيل'));
      await tester.pumpAndSettle();
      expect(find.byType(RedeemScreen), findsOneWidget);
    });

    testWidgets('without COUPON_REDEMPTION the end card only says it is unavailable', (tester) async {
      final app = await pump(tester, coupon: false);
      await go(tester, app, '/decks/d1/browse');
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('التالي'));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('browse.lockedEnd')), findsOneWidget);
      expect(find.text('هذا المحتوى غير متاح على حسابك'), findsOneWidget);
      expect(find.text('إدخال كود التفعيل'), findsNothing);
    });

    testWidgets('a locked deck cannot be studied', (tester) async {
      final app = await pump(tester);
      await go(tester, app, '/decks/d1/study');
      expect(find.byKey(const Key('study.locked')), findsOneWidget);
      expect(find.text('عرض التقييم'), findsNothing);
      expect(find.text('اقلب البطاقة'), findsNothing);
      expect(await SrsStore(app.db).pendingLogs(), isEmpty);
    });
  });

  group('single-face cards (v3 §6)', () {
    final d = deck('d1', title: 'بطاقات جاهزة', isFree: true);

    Future<PumpedApp> pump(WidgetTester tester) async {
      useSize(tester, const Size(390, 1000));
      return pumpApp(
        tester,
        signedInAs: testMe,
        clock: () => t0,
        arrangeFlashcards: (f) {
          when(() => f.deck('d1')).thenAnswer((_) async => d);
          when(() => f.deckCards('d1')).thenAnswer((_) async => deckCards(d, [card(0, back: false), card(1)]));
        },
      );
    }

    testWidgets('browse shows the front only, with no flip button or hint', (tester) async {
      final app = await pump(tester);
      await go(tester, app, '/decks/d1/browse');
      expect(find.text('img:f0'), findsOneWidget);
      expect(find.text('اقلب البطاقة'), findsNothing);
      expect(find.text('اسحب يميناً ويساراً للتنقّل'), findsOneWidget);
      await tester.tap(find.text('img:f0'));
      await tester.pumpAndSettle();
      expect(find.text('img:f0'), findsOneWidget);
      expect(find.text('img:b0'), findsNothing);
      // A two-sided card still flips.
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('اقلب البطاقة'), findsOneWidget);
    });

    testWidgets('study: «عرض التقييم» reveals the ratings and rating works', (tester) async {
      final app = await pump(tester);
      await go(tester, app, '/decks/d1/study');
      expect(find.text('img:f0'), findsOneWidget);
      expect(find.text('اقلب البطاقة'), findsNothing);
      await tester.tap(find.text('عرض التقييم'));
      await tester.pumpAndSettle();
      expect(find.text('img:f0'), findsOneWidget);
      expect(find.text('جيد'), findsOneWidget);
      await tester.tap(find.text('جيد'));
      await tester.pumpAndSettle();
      final logs = await SrsStore(app.db).pendingLogs();
      expect([for (final l in logs) l.flashcardId], ['c0']);
      await flushSync(tester);
    });
  });

  group('stars (v3 §8)', () {
    testWidgets('the star on an official card saves it; again removes it', (tester) async {
      useSize(tester, const Size(390, 1000));
      final d = deck('d1', isFree: true);
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeFlashcards: (f) {
          when(() => f.deck('d1')).thenAnswer((_) async => d);
          when(() => f.deckCards('d1')).thenAnswer((_) async => deckCards(d, [card(0), card(1)]));
        },
        arrangeLearning: (l) {
          when(() => l.addBookmark(any(), any())).thenAnswer((_) async {});
          when(() => l.removeBookmark(any(), any())).thenAnswer((_) async {});
          when(
            () => l.bookmarks(),
          ).thenAnswer((_) async => const BookmarkList(items: [], nextCursor: null, urlsExpireAt: ''));
        },
      );
      await go(tester, app, '/decks/d1/browse');
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('card.star')));
      await tester.pumpAndSettle();
      verify(() => app.learning.addBookmark(BookmarkItemType.flashcard, 'c0')).called(1);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('card.star')));
      await tester.pumpAndSettle();
      verify(() => app.learning.removeBookmark(BookmarkItemType.flashcard, 'c0')).called(1);
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);

      // Study has the star too.
      await go(tester, app, '/decks/d1/study');
      expect(find.byKey(const Key('card.star')), findsOneWidget);
    });

    testWidgets('the star on an own card saves it as a user card, after syncing it', (tester) async {
      useSize(tester, const Size(390, 1000));
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeLearning: (l) => when(() => l.addBookmark(any(), any())).thenAnswer((_) async {}),
      );
      final store = MyDecksStore(app.db);
      await store.saveDeck(id: 'g1', name: 'مجموعتي', subjectId: 'p', templateKey: 'sun');
      await store.saveCustomCard(id: 'u1', deckId: 'g1', frontText: 'سؤال', backText: 'جواب');
      await go(tester, app, '${Routes.myDeckStudy}/g1/browse');
      // Own cards are drawn on their group's frame.
      expect(find.byKey(const Key('template.sun')), findsOneWidget);
      await tester.tap(find.byKey(const Key('card.star')));
      await tester.pumpAndSettle();
      verify(() => app.myDecks.push(any())).called(greaterThan(0));
      verify(() => app.learning.addBookmark(BookmarkItemType.userCard, 'u1')).called(1);
      await flushSync(tester);
    });
  });

  group('saved cards grouped subject › unit › deck (v3 §8)', () {
    Bookmark starred(String id, {BookmarkGroup? group, String subjectId = 'en'}) => Bookmark(
      id: 'b$id',
      itemType: BookmarkItemType.flashcard,
      itemId: id,
      createdAt: '2026-11-01T00:00:00Z',
      locked: false,
      available: true,
      titleAr: 'بطاقة $id',
      subjectId: subjectId,
      subjectNameAr: 'اللغة الإنكليزية',
      question: null,
      deck: null,
      card: StudentCard(
        id: id,
        deckId: 'dv',
        sortOrder: 0,
        contentVersion: 1,
        front: image('f$id'),
        back: image('b$id'),
      ),
      userCard: null,
      group: group,
    );
    const vocab = BookmarkGroup(
      subjectId: 'en',
      subjectNameAr: 'اللغة الإنكليزية',
      unitId: 'u1',
      unitTitleAr: 'Unit 1',
      lessonId: null,
      lessonTitleAr: null,
      deckId: 'dv',
      deckTitle: 'Vocabulary',
      ownDeck: false,
    );
    const grammar = BookmarkGroup(
      subjectId: 'en',
      subjectNameAr: 'اللغة الإنكليزية',
      unitId: 'u1',
      unitTitleAr: 'Unit 1',
      lessonId: null,
      lessonTitleAr: null,
      deckId: 'dg',
      deckTitle: 'Grammar',
      ownDeck: false,
    );

    test('one group per deck, ordered by subject, unit and deck', () {
      final groups = starGroups([
        starred('c1', group: vocab),
        starred('c2', group: grammar),
        starred('c3', group: vocab),
        starred('c4'),
      ]);
      expect([for (final g in groups) g.title], ['Grammar', 'Vocabulary']);
      expect(groups[1].path, ['اللغة الإنكليزية', 'Unit 1', 'Vocabulary']);
      expect(groups[1].cards.length, 2);
    });

    testWidgets('a row per deck with its stars opens those cards; hard and ungrouped cards stay single', (
      tester,
    ) async {
      useSize(tester, const Size(390, 1400));
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeLearning: (l) {
          when(() => l.bookmarkKeys()).thenAnswer(
            (_) async => [
              for (final id in ['c1', 'c2', 'c3', 'c4', 'c9'])
                BookmarkKey(itemType: BookmarkItemType.flashcard, itemId: id),
            ],
          );
          when(() => l.bookmarks()).thenAnswer(
            (_) async => BookmarkList(
              items: [
                starred('c1', group: vocab),
                starred('c2', group: vocab),
                starred('c3', group: vocab),
                starred('c4', group: grammar),
                starred('c9'),
              ],
              nextCursor: null,
              urlsExpireAt: '',
            ),
          );
        },
      );
      await SrsStore(
        app.db,
      ).putState('c2', CardState.newCard(0).copyWith(state: CardStateName.review, lapses: 3, ease: 1.9));
      app.container.invalidate(hardCardsProvider);
      await go(tester, app, '${Routes.saved}?filter=cards&subjectId=en');
      expect(find.byKey(const Key('saved.group.deck:dv')), findsOneWidget);
      expect(find.text('3 ★'), findsOneWidget);
      expect(find.text('1 ★'), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('saved.group.deck:dv')), matching: find.textContaining('Vocabulary')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(const Key('saved.group.deck:dv')), matching: find.textContaining('Unit 1')),
        findsOneWidget,
      );
      // The ungrouped card is a row of its own; the grouped ones are not.
      expect(find.textContaining('c9'), findsOneWidget);
      expect(find.textContaining('c1'), findsNothing);
      // The hard card stays a single row, marked.
      expect(find.textContaining('c2'), findsOneWidget);
      expect(find.text('صعبة'), findsOneWidget);

      await tester.tap(find.byKey(const Key('saved.group.deck:dv')));
      await tester.pumpAndSettle();
      expect(find.byType(StarredCardsScreen), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('img:fc1'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });
  });

  group('اصنع بطاقاتك الخاصة (v3 §7)', () {
    final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3]);

    Future<PumpedApp> pump(WidgetTester tester, {Size size = const Size(390, 1400)}) async {
      useSize(tester, size);
      return pumpApp(
        tester,
        signedInAs: testMe,
        pickedImage: png,
        arrangeCatalog: (c) => when(
          () => c.subjects(any()),
        ).thenAnswer((_) async => [catalogSubject('p', 'الفيزياء'), catalogSubject('c', 'الكيمياء')]),
      );
    }

    testWidgets('subject → template → name → cards → done saves a deck with subjectId and templateKey', (tester) async {
      final app = await pump(tester);
      await go(tester, app, Routes.makeCards);
      expect(find.byType(MakeCardsScreen), findsOneWidget);
      expect(find.byKey(const Key('makeCards.template.physics')), findsNothing); // not bundled
      for (final k in ['grid', 'sun', 'clouds', 'stars']) {
        expect(find.byKey(Key('makeCards.template.$k')), findsOneWidget, reason: k);
      }
      await tester.tap(find.byKey(const Key('makeCards.subject.c')));
      await tester.tap(find.byKey(const Key('makeCards.template.stars')));
      await tester.pumpAndSettle();
      expect(find.text('اختر التصميم الذي يعجبك لبطاقات مجموعتك في الكيمياء'), findsOneWidget);
      await tester.tap(find.byKey(const Key('makeCards.start')));
      await tester.pumpAndSettle();
      expect(find.byType(CreateGroupScreen), findsOneWidget);

      await tester.enterText(find.byKey(const Key('group.name')), 'قوانين الكيمياء');
      await tester.pump();
      await tester.tap(find.byKey(const Key('group.next')));
      await tester.pumpAndSettle();
      expect(find.text('البطاقة 1'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('card.front')), 'ما هو الحمض؟');
      await tester.enterText(find.byKey(const Key('card.back')), 'مادة تعطي H+');
      await tester.pump();
      await tester.tap(find.byKey(const Key('card.next')));
      await tester.pumpAndSettle();
      expect(find.text('البطاقة 2'), findsOneWidget);

      // The second card's back is an image only.
      await tester.enterText(find.byKey(const Key('card.front')), 'جدول دوري');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('card.backImage')));
      await tester.tap(find.byKey(const Key('card.backImage')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('من المعرض'));
      await tester.pumpAndSettle();
      expect(find.text('local-image:${png.length}'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('card.finish')));
      await tester.tap(find.byKey(const Key('card.finish')));
      await tester.pumpAndSettle();

      expect(find.text('تم إنشاء مجموعة الفلاش كاردز!'), findsOneWidget);
      expect(find.text('ما هو الحمض؟'), findsOneWidget);
      expect(find.text('جدول دوري'), findsOneWidget);

      final store = MyDecksStore(app.db);
      final decks = await store.decks();
      expect(decks, hasLength(1));
      final g = decks.single.deck;
      expect((g.name, g.subjectId, g.templateKey, g.dirty), ('قوانين الكيمياء', 'c', 'stars', true));
      final cards = await store.cards(g.id);
      expect([for (final c in cards) c.frontText], ['ما هو الحمض؟', 'جدول دوري']);
      expect(cards[1].backLocalImage, png);
      // The sync sends both.
      expect(MyDecksRepository.deckWrite(g).toJson()['templateKey'], 'stars');
      expect(MyDecksRepository.deckWrite(g).toJson()['subjectId'], 'c');

      // «إضافة بطاقات أخرى» goes back to the cards.
      await tester.ensureVisible(find.byKey(const Key('done.addMore')));
      await tester.tap(find.byKey(const Key('done.addMore')));
      await tester.pumpAndSettle();
      expect(find.text('البطاقة 3'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('card.front')), 'سؤال ثالث');
      await tester.enterText(find.byKey(const Key('card.back')), 'جواب');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('card.finish')));
      await tester.tap(find.byKey(const Key('card.finish')));
      await tester.pumpAndSettle();
      expect(await store.cards(g.id), hasLength(3));

      await tester.ensureVisible(find.byKey(const Key('done.open')));
      await tester.tap(find.byKey(const Key('done.open')));
      await tester.pumpAndSettle();
      expect(find.byType(GroupScreen), findsOneWidget);
      expect(location(app), '${Routes.makeCardsGroups}/${g.id}');
      // The preview carousel draws the cards on the chosen frame.
      expect(find.byKey(const Key('template.stars')), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      await flushSync(tester);
    });

    Future<MyDecksStore> seed(PumpedApp app) async {
      final store = MyDecksStore(app.db);
      await store.saveDeck(id: 'g1', name: 'قوانين الفيزياء', subjectId: 'p', templateKey: 'grid');
      await store.saveDeck(id: 'g2', name: 'تفاعلات', subjectId: 'c', templateKey: 'clouds');
      await store.saveCustomCard(id: 'k1', deckId: 'g1', frontText: 'F = ma', backText: 'قانون نيوتن الثاني');
      await store.saveCustomCard(id: 'k2', deckId: 'g1', frontText: 'v = d/t', backText: 'السرعة');
      return store;
    }

    testWidgets('مجموعاتي: groups per subject with «مراجعة» and «تعديل»; delete after confirming', (tester) async {
      final app = await pump(tester);
      final store = await seed(app);
      await go(tester, app, Routes.makeCardsGroups);
      expect(find.byType(MyGroupsScreen), findsOneWidget);
      expect(find.byKey(const Key('group.g1')), findsOneWidget);
      expect(find.byKey(const Key('group.g2')), findsOneWidget);
      final pills = find.byKey(const Key('groups.pills'));
      await tester.tap(find.descendant(of: pills, matching: find.text('الكيمياء')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('group.g1')), findsNothing);
      expect(find.byKey(const Key('group.g2')), findsOneWidget);
      // An empty group cannot be reviewed.
      await tester.tap(find.byKey(const Key('group.g2.review')));
      await tester.pumpAndSettle();
      expect(find.byType(MyGroupsScreen), findsOneWidget);

      await go(tester, app, '${Routes.makeCardsGroups}?subjectId=p');
      expect(find.byKey(const Key('group.g2')), findsNothing);
      await tester.tap(find.byKey(const Key('group.g1.edit')));
      await tester.pumpAndSettle();
      expect(find.byType(EditGroupScreen), findsOneWidget);
      for (final t in ['تعديل البطاقات', 'إضافة بطاقات', 'حذف المجموعة']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }

      // تعديل البطاقات: delete one card.
      await tester.tap(find.byKey(const Key('editGroup.cards')));
      await tester.pumpAndSettle();
      expect(find.byType(GroupCardsScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('groupCard.k2.delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف').last);
      await tester.pumpAndSettle();
      expect(await store.cards('g1'), hasLength(1));
      Navigator.of(tester.element(find.byType(GroupCardsScreen))).pop();
      await tester.pumpAndSettle();

      // حذف المجموعة: cancel keeps it, confirm deletes it.
      await tester.tap(find.byKey(const Key('editGroup.delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect((await store.deck('g1'))!.deletedAt, isNull);
      await tester.tap(find.byKey(const Key('editGroup.delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف المجموعة').last);
      await tester.pumpAndSettle();
      expect((await store.deck('g1'))!.deletedAt, isNotNull);
      expect(find.byType(MyGroupsScreen), findsOneWidget);
      expect(find.byKey(const Key('group.g1')), findsNothing);
      await flushSync(tester);
    });

    testWidgets('group page: settings change name, subject and frame; stats; add cards', (tester) async {
      final app = await pump(tester);
      final store = await seed(app);
      await go(tester, app, '${Routes.makeCardsGroups}/g1');
      expect(find.byType(GroupScreen), findsOneWidget);
      expect(find.byKey(const Key('template.grid')), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      for (final t in ['مراجعة المجموعة', 'عرض البطاقات', 'إعدادات المجموعة', 'إحصائيات التقدم']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }

      await tester.tap(find.byKey(const Key('groupPage.stats')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('group.stats')), findsOneWidget);
      expect(find.text('جديدة 2'), findsOneWidget);
      Navigator.of(tester.element(find.byKey(const Key('group.stats')))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('groupPage.settings')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('settings.name')), 'قوانين الحركة');
      await tester.tap(find.byKey(const Key('makeCards.subject.c')));
      await tester.tap(find.byKey(const Key('makeCards.template.sun')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('settings.save')));
      await tester.tap(find.byKey(const Key('settings.save')));
      await tester.pumpAndSettle();
      final d = (await store.deck('g1'))!;
      expect((d.name, d.subjectId, d.templateKey), ('قوانين الحركة', 'c', 'sun'));
      expect(find.byKey(const Key('template.sun')), findsOneWidget);

      await tester.tap(find.byKey(const Key('groupPage.add')));
      await tester.pumpAndSettle();
      expect(find.byType(CreateGroupScreen), findsOneWidget);
      expect(find.text('البطاقة 1'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('card.front')), 'a = Δv/Δt');
      await tester.enterText(find.byKey(const Key('card.back')), 'التسارع');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('card.finish')));
      await tester.tap(find.byKey(const Key('card.finish')));
      await tester.pumpAndSettle();
      expect(find.text('تمت إضافة البطاقات!'), findsOneWidget);
      expect(await store.cards('g1'), hasLength(3));
      // The new group keeps its frame when only renamed elsewhere.
      await store.saveDeck(id: 'g1', name: 'اسم آخر', subjectId: 'c');
      expect((await store.deck('g1'))!.templateKey, 'sun');
      await flushSync(tester);
    });

    test('unknown frames fall back to the grid; the owner\'s frames need their PNG', () {
      expect(CardTemplates.of('newer-frame'), CardTemplates.grid);
      expect(CardTemplates.of(null), isNull);
      expect(CardTemplates.physics.assetPath, 'assets/templates/physics.png');
      expect([for (final t in CardTemplates.drawn) t.key], ['grid', 'sun', 'clouds', 'stars']);
    });

    test('the server feed carries the frame into the local deck', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = MyDecksStore(db);
      await store.applyServer(
        const UserContentChanges(
          decks: [
            UserDeck(
              id: 'g9',
              name: 'من جهاز آخر',
              subjectId: 'p',
              color: null,
              templateKey: 'clouds',
              sortOrder: 0,
              cardCount: 0,
              createdAt: '2026-11-01T00:00:00Z',
              updatedAt: '2026-11-01T00:00:00Z',
              deletedAt: null,
            ),
          ],
          cards: [],
          cursor: 'x',
          hasMore: false,
          urlsExpireAt: '',
        ),
      );
      expect((await store.deck('g9'))!.templateKey, 'clouds');
    });
  });

  group('layout at 360×800 with large text (v3 §6–§8)', () {
    for (final dark in [false, true]) {
      testWidgets('card screens lay out without overflow (${dark ? 'dark' : 'light'})', (tester) async {
        useSize(tester, const Size(360, 800));
        tester.platformDispatcher.textScaleFactorTestValue = 1.16;
        tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final locked = deck('d1', title: 'قوانين الفيزياء للبكالوريا', locked: true, cardCount: 120);
        final app = await pumpApp(
          tester,
          signedInAs: testMe,
          arrangeCatalog: (c) => when(() => c.subjects(any())).thenAnswer(
            (_) async => [
              catalogSubject('p', 'الفيزياء'),
              catalogSubject('c', 'الكيمياء'),
              catalogSubject('e', 'اللغة الإنكليزية'),
            ],
          ),
          arrangeFlashcards: (f) {
            when(
              () => f.plengoDecks(
                subjectId: any(named: 'subjectId'),
                educationLevelId: any(named: 'educationLevelId'),
              ),
            ).thenAnswer((_) async => plengoList);
            when(() => f.deck('d1')).thenAnswer((_) async => locked);
            when(
              () => f.deckCards('d1'),
            ).thenAnswer((_) async => deckCards(locked, [card(0, back: false)], preview: true));
          },
          arrangeLearning: (l) => when(
            () => l.bookmarks(),
          ).thenAnswer((_) async => const BookmarkList(items: [], nextCursor: null, urlsExpireAt: '')),
        );
        final store = MyDecksStore(app.db);
        await store.saveDeck(
          id: 'g1',
          name: 'قوانين الفيزياء الأساسية للصف الثالث',
          subjectId: 'p',
          templateKey: 'stars',
        );
        await store.saveCustomCard(
          id: 'k1',
          deckId: 'g1',
          frontText: 'ما قانون قوة الإرجاع في النابض؟',
          backText: 'F = -kx',
        );
        for (final path in [
          Routes.plengoCards,
          '${Routes.plengoCards}/decks/d1',
          '/decks/d1/browse',
          Routes.makeCards,
          '${Routes.makeCardsNew}?subjectId=p&template=sun',
          Routes.makeCardsGroups,
          '${Routes.makeCardsGroups}/g1',
          '${Routes.makeCardsGroups}/g1/edit',
          '${Routes.makeCardsGroups}/g1/settings',
          '${Routes.makeCardsGroups}/g1/cards',
          '${Routes.myDeckStudy}/g1/study',
        ]) {
          await go(tester, app, path);
          expect(tester.takeException(), isNull, reason: path);
        }
        // The card step of the creation flow and the locked end card.
        await go(tester, app, '${Routes.makeCardsNew}?subjectId=p&template=clouds');
        await tester.enterText(find.byKey(const Key('group.name')), 'مجموعة');
        await tester.pump();
        await tester.tap(find.byKey(const Key('group.next')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await go(tester, app, '/decks/d1/browse');
        await tester.tap(find.text('التالي'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('browse.lockedEnd')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await flushSync(tester);
      });
    }
  });
}
