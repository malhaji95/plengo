import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/questions/question_providers.dart';
import 'package:plengo/features/questions/questions_screen.dart';

import 'helpers.dart';

StudentQuestion question(
  String id,
  StudentQuestionType type, {
  bool locked = false,
  bool isFree = false,
  String? text,
  List<StudentOption>? options,
  String? lessonId,
}) => StudentQuestion(
  id: id,
  type: type,
  subjectId: 'p',
  teacherTrackId: null,
  unitId: null,
  lessonId: lessonId,
  sortOrder: 0,
  difficulty: null,
  isFree: isFree,
  locked: locked,
  questionText: locked ? null : text,
  options: locked ? null : options,
);

final mcq = question(
  'q1',
  StudentQuestionType.mcq,
  isFree: true,
  text: 'ما وحدة القوة؟',
  options: const [
    StudentOption(id: 'o1', text: 'النيوتن'),
    StudentOption(id: 'o2', text: 'الجول'),
  ],
);
final written = question('q2', StudentQuestionType.written, text: 'ما عاصمة سوريا؟');
final locked = question('q3', StudentQuestionType.trueFalse, locked: true);

const lessonId = 'l1';

SubjectOutline outlineWithQuestions() => SubjectOutline(
  subject: subject('p', 'الفيزياء'),
  units: const [],
  lessons: const [Lesson(id: lessonId, subjectId: 'p', unitId: null, code: 'motion', titleAr: 'الحركة', sortOrder: 0)],
  tracks: const [],
  access: noAccess,
  questionCount: const ContentCount(total: 3, free: 1),
  deckCount: noQuestions,
  quizCount: noQuestions,
);

void main() {
  test('Arabic count agreement for questions', () {
    expect(questionCountLabel(1), 'سؤال واحد');
    expect(questionCountLabel(2), 'سؤالان');
    expect(questionCountLabel(7), '7 أسئلة');
    expect(questionCountLabel(30), '30 سؤالاً');
  });

  testWidgets('lists questions with locked ones as metadata, then practices with server checks', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer((_) async => outlineWithQuestions()),
      arrangeQuestions: (q) {
        when(() => q.page(any(), cursor: any(named: 'cursor'))).thenAnswer(
          (_) async =>
              StudentQuestionPage(items: [mcq, written, locked], nextCursor: null, totalCount: 3, accessibleCount: 2),
        );
        when(() => q.check('q1', selectedOptionId: 'o2')).thenAnswer(
          (_) async => const CheckResult(
            isCorrect: false,
            correctOptionId: 'o1',
            correctAnswer: null,
            explanation: 'النيوتن وحدة القوة',
          ),
        );
        when(() => q.check('q2', writtenAnswer: 'دمشق')).thenAnswer(
          (_) async =>
              const CheckResult(isCorrect: true, correctOptionId: null, correctAnswer: 'دِمَشْق', explanation: null),
        );
      },
    );
    app.container.read(routerProvider).go('/subjects/p');
    await tester.pumpAndSettle();
    expect(find.text('3 أسئلة · 1 مجاني'), findsOneWidget);
    await tester.tap(find.text('بنك الأسئلة'));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionsScreen), findsOneWidget);
    expect(find.text('2 من 3 أسئلة متاح'), findsOneWidget);
    expect(find.text('سؤال مقفل'), findsOneWidget);
    expect(find.text('هذا المحتوى يحتاج إلى تفعيل'), findsOneWidget);

    await tester.tap(find.text('ابدأ التدريب'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeScreen), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'تحقق')).onPressed, isNull);
    await tester.tap(find.text('الجول'));
    await tester.pump();
    await tester.tap(find.text('تحقق'));
    await tester.pumpAndSettle();
    verify(() => app.questions.check('q1', selectedOptionId: 'o2')).called(1);
    expect(find.text('إجابة خاطئة'), findsOneWidget);
    expect(find.text('النيوتن وحدة القوة'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget); // the correct option is shown

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('written-answer')), 'دمشق');
    await tester.pump();
    await tester.tap(find.text('تحقق'));
    await tester.pumpAndSettle();
    expect(find.text('إجابة صحيحة'), findsOneWidget);
    expect(find.textContaining('صحيحة 1 من 2'), findsOneWidget);
    await tester.tap(find.text('إنهاء'));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionsScreen), findsOneWidget);
  });

  testWidgets('a lesson opens its own page: its decks, quizzes and questions', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer((_) async => outlineWithQuestions()),
      arrangeQuestions: (q) => when(() => q.page(any(), cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => StudentQuestionPage(items: [mcq, written], nextCursor: null, totalCount: 2, accessibleCount: 2),
      ),
      arrangeFlashcards: (f) => when(() => f.decks(any())).thenAnswer(
        (_) async => const [
          StudentDeck(
            id: 'd1',
            subjectId: 'p',
            teacherTrackId: null,
            unitId: null,
            lessonId: lessonId,
            titleAr: 'مفردات الحركة',
            description: null,
            coverUrl: null,
            cardCount: 12,
            isFree: false,
            locked: false,
            contentVersion: 1,
            sortOrder: 0,
          ),
        ],
      ),
      arrangeLearning: (l) => when(() => l.quizzes(any())).thenAnswer((_) async => const []),
    );
    app.container.read(routerProvider).go('/subjects/p');
    await tester.pumpAndSettle();
    await tester.tap(find.text('الحركة'));
    await tester.pumpAndSettle();
    const query = (subjectId: 'p', teacherTrackId: null, unitId: null, lessonId: lessonId);
    expect(verify(() => app.flashcards.decks(captureAny())).captured.single, query);
    expect(verify(() => app.questions.page(captureAny(), cursor: any(named: 'cursor'))).captured.single, query);
    expect(find.text('البطاقات التعليمية'), findsOneWidget);
    expect(find.text('مفردات الحركة'), findsOneWidget);
    expect(find.text('الاختبارات'), findsNothing); // no quizzes in this lesson
    expect(find.text('سؤالان'), findsOneWidget);

    await tester.tap(find.text('أسئلة الدرس'));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionsScreen), findsOneWidget);
    expect(
      app.container.read(routerProvider).routeInformationProvider.value.uri.toString(),
      '/subjects/p/questions?lessonId=l1',
    );
  });

  testWidgets('an empty lesson says so', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer((_) async => outlineWithQuestions()),
      arrangeQuestions: (q) => when(() => q.page(any(), cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const StudentQuestionPage(items: [], nextCursor: null, totalCount: 0, accessibleCount: 0),
      ),
      arrangeFlashcards: (f) => when(() => f.decks(any())).thenAnswer((_) async => const []),
      arrangeLearning: (l) => when(() => l.quizzes(any())).thenAnswer((_) async => const []),
    );
    app.container.read(routerProvider).go('/subjects/p/lessons/l1');
    await tester.pumpAndSettle();
    expect(find.text('لا يوجد محتوى في هذا الدرس بعد'), findsOneWidget);
  });
}
