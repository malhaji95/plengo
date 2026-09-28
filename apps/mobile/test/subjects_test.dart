import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/account/placement_screen.dart';
import 'package:plengo/features/subjects/subject_screen.dart';

import 'helpers.dart';

Future<void> openSubjectsTab(WidgetTester tester) async {
  await tester.tap(find.text('المواد').last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(registerFallbacks);

  testWidgets('opens on the student level, and every level is browsable (spec §8.9)', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) {
        when(() => c.subjects(any())).thenAnswer((inv) async {
          final q =
              inv.positionalArguments.first
                  as ({String levelId, String? universityId, String? facultyId, String? academicYearId});
          return q.levelId == 'l12'
              ? [subject('p', 'الفيزياء', description: 'فيزياء البكالوريا'), subject('m', 'الرياضيات')]
              : [subject('g9', 'العلوم', levelId: 'l9')];
        });
      },
    );
    await openSubjectsTab(tester);

    final chip = tester.widget<ChoiceChip>(fieldByKey('level.grade-12'));
    expect(chip.selected, isTrue);
    expect(find.text('الفيزياء'), findsOneWidget);
    expect(find.text('فيزياء البكالوريا'), findsOneWidget);

    await tester.tap(fieldByKey('level.grade-9'));
    await tester.pumpAndSettle();
    expect(find.text('العلوم'), findsOneWidget);
    expect(find.text('الفيزياء'), findsNothing);
    verify(
      () => app.catalog.subjects((levelId: 'l9', universityId: null, facultyId: null, academicYearId: null)),
    ).called(1);
  });

  testWidgets('the college level shows the optional university filter', (tester) async {
    await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.universities()).thenAnswer(
        (_) async => const [University(id: 'u1', code: 'damascus', nameAr: 'جامعة دمشق', sortOrder: 0, isActive: true)],
      ),
    );
    await openSubjectsTab(tester);
    expect(fieldByKey('filter.university'), findsNothing);
    await tester.tap(fieldByKey('level.college'));
    await tester.pumpAndSettle();
    expect(fieldByKey('filter.university'), findsOneWidget);
    expect(find.text('لا توجد مواد هنا بعد'), findsOneWidget);
  });

  testWidgets('a subject opens its outline: units with lessons, then general lessons', (tester) async {
    Lesson lesson(String id, String title, {String? unitId}) =>
        Lesson(id: id, subjectId: 'p', unitId: unitId, code: id, titleAr: title, sortOrder: 0);
    await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) {
        when(() => c.subjects(any())).thenAnswer((_) async => [subject('p', 'الفيزياء')]);
        when(() => c.outline('p')).thenAnswer(
          (_) async => SubjectOutline(
            subject: subject('p', 'الفيزياء'),
            units: [
              UnitWithLessons(
                id: 'u1',
                subjectId: 'p',
                code: 'mech',
                titleAr: 'الميكانيك',
                sortOrder: 0,
                lessons: [
                  lesson('l1', 'الحركة', unitId: 'u1'),
                  lesson('l2', 'القوى', unitId: 'u1'),
                ],
              ),
            ],
            lessons: [lesson('l0', 'مراجعة عامة')],
            access: noAccess,
            questionCount: noQuestions,
            deckCount: noQuestions,
            quizCount: noQuestions,
            tracks: const [],
          ),
        );
      },
    );
    await openSubjectsTab(tester);
    await tester.tap(find.text('الفيزياء'));
    await tester.pumpAndSettle();

    expect(find.byType(SubjectScreen), findsOneWidget);
    expect(find.text('الميكانيك'), findsOneWidget);
    expect(find.text('درسان'), findsOneWidget);
    expect(find.text('الحركة'), findsOneWidget);
    expect(find.text('دروس عامة'), findsOneWidget);
    expect(find.text('مراجعة عامة'), findsOneWidget);
  });

  testWidgets('changing the placement in settings saves it and updates the profile', (tester) async {
    const updated = Me(
      id: 'u1',
      email: 'student@example.com',
      emailVerified: true,
      role: MeRole.student,
      fullName: 'سارة أحمد',
      educationLevelId: 'l9',
      universityId: null,
      facultyId: null,
      academicYearId: null,
      avatarUrl: null,
    );
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.updatePlacement(any())).thenAnswer((_) async => updated),
    );
    await tester.tap(find.text('حسابي').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('المرحلة التعليمية'));
    await tester.pumpAndSettle();
    expect(find.byType(PlacementScreen), findsOneWidget);

    await tester.tap(fieldByKey('placement.level'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الصف التاسع').last);
    await tester.pumpAndSettle();
    await tester.tap(fieldByKey('placement.save'));
    await tester.pumpAndSettle();

    verify(
      () => app.catalog.updatePlacement((levelId: 'l9', universityId: null, facultyId: null, academicYearId: null)),
    ).called(1);
    expect(find.byType(PlacementScreen), findsNothing);
    expect(app.container.read(authControllerProvider).value?.educationLevelId, 'l9');
  });
}
