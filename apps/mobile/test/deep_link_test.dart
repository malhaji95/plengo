import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/subjects/subject_screen.dart';

import 'helpers.dart';

void main() {
  testWidgets('a deep link survives session restore (web reload)', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer(
        (_) async => SubjectOutline(
          subject: subject('p', 'الفيزياء'),
          units: const [],
          lessons: const [],
          tracks: const [],
          access: noAccess,
          questionCount: noQuestions,
          deckCount: noQuestions,
          quizCount: noQuestions,
        ),
      ),
    );
    // Simulate the browser opening /subjects/p while the session is still being restored.
    app.container.invalidate(authControllerProvider);
    app.container.read(routerProvider).go('/subjects/p');
    await tester.pumpAndSettle();
    expect(find.byType(SubjectScreen), findsOneWidget);
    expect(app.container.read(routerProvider).routeInformationProvider.value.uri.path, '/subjects/p');
  });
}
