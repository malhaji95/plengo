import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/api_client.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/core/auth/token_store.dart';
import 'package:plengo/features/offline/offline_providers.dart';

import 'flashcards_test.dart' show deck;
import 'helpers.dart';
import 'offline_packs_test.dart' show PackServer, cardItem, deckItem, deckKey, scope;

void main() {
  testWidgets('a deck page shows its size, downloads it, and the storage screen lists it (§22.2)', (tester) async {
    final server = PackServer()
      ..items['d1'] = deckItem(free: true)
      ..items['c1'] = cardItem('c1')
      ..items['c2'] = cardItem('c2')
      ..packs[deckKey] = ['d1', 'c1', 'c2'];
    final client = ApiClient(
      baseUrl: 'http://api.test',
      tokens: MemoryTokenStore(),
      platform: 'android',
      appVersion: '1.0.0',
      useCookies: false,
      adapter: server,
    );
    const catalog = OfflineScopeCatalog(
      scope: scope,
      titleAr: 'الكيمياء',
      entitled: true,
      // The same version the scripted manifest reports once downloaded.
      packs: [
        OfflinePack(
          packKey: deckKey,
          kind: OfflinePackKind.deck,
          unitId: null,
          deckId: 'd1',
          titleAr: 'حزمة',
          itemCount: 3,
          sizeBytes: 3000,
          version: 'd1@1,c1@1,c2@1',
          premium: false,
        ),
      ],
      sizeBytes: 3000,
    );
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      offlinePacks: true,
      arrangeFlashcards: (f) => when(() => f.deck('d1')).thenAnswer((_) async => deck()),
      extraOverrides: [
        apiClientProvider.overrideWithValue(client),
        offlineScopeCatalogProvider.overrideWith((ref, q) async => catalog),
      ],
    );
    app.container.read(routerProvider).go('${Routes.decks}/d1');
    await tester.pumpAndSettle();
    expect(find.text('تحميل البطاقات'), findsOneWidget);
    expect(find.text('الحجم التقريبي: 3 كيلوبايت'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'تحميل'));
    // The download runs in the background of the app; give it time.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(server.calls.where((c) => c.uri.host == 'cdn.test'), hasLength(4));
    expect(find.textContaining('محمّل للاستخدام دون اتصال'), findsOneWidget);

    app.container.read(routerProvider).go(Routes.offlineStorage);
    await tester.pumpAndSettle();
    expect(find.text('التحميل عبر Wi-Fi فقط'), findsOneWidget);
    expect(find.text('الكيمياء'), findsOneWidget);
    expect(find.text('حزمة'), findsOneWidget);
    await tester.tap(find.byTooltip('حذف'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(find.text('حزمة'), findsNothing);
  });

  testWidgets('offline packs are not offered on web (§22.8)', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeFlashcards: (f) => when(() => f.deck('d1')).thenAnswer((_) async => deck()),
    );
    app.container.read(routerProvider).go('${Routes.decks}/d1');
    await tester.pumpAndSettle();
    expect(find.text('تحميل البطاقات'), findsNothing);
    app.container.read(routerProvider).go(Routes.account);
    await tester.pumpAndSettle();
    expect(find.text('المحتوى المحمّل'), findsNothing);
  });

  testWidgets('statistics show an offline approximation without a connection (§22.6)', (tester) async {
    const offline = ApiException('NETWORK_ERROR', ApiException.networkMessage);
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeLearning: (l) {
        when(() => l.overview()).thenThrow(offline);
        when(() => l.trend()).thenThrow(offline);
        when(() => l.flashcardStats()).thenThrow(offline);
      },
    );
    app.container.read(routerProvider).go(Routes.stats);
    await tester.pumpAndSettle();
    expect(find.textContaining('أنت غير متصل'), findsOneWidget);
    expect(find.text('اختبارات على الجهاز'), findsOneWidget);
  });
}
