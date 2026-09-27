import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/teachers/teacher_screen.dart';
import 'package:plengo/features/teachers/track_screen.dart';

import 'helpers.dart';

Teacher teacher({bool following = false, int followers = 0}) => Teacher(
  id: 't1',
  nameAr: 'أ. أحمد',
  slug: 'ahmad',
  photoUrl: null,
  shortDescription: 'مدرّس فيزياء',
  followerCount: followers,
  isFollowing: following,
);

TeacherProfile profile({bool following = false, int followers = 0}) => TeacherProfile(
  teacher: TeacherDetail(
    id: 't1',
    nameAr: 'أ. أحمد',
    slug: 'ahmad',
    photoUrl: null,
    shortDescription: 'مدرّس فيزياء',
    followerCount: followers,
    isFollowing: following,
    bio: 'خبرة عشرين عاماً في تدريس الفيزياء',
  ),
  tracks: const [
    TeacherTrack(
      id: 'tr1',
      teacherId: 't1',
      teacherNameAr: 'أ. أحمد',
      subjectId: 'p',
      subjectNameAr: 'الفيزياء',
      educationLevelId: 'l12',
      titleAr: 'أ. أحمد — فيزياء بكالوريا',
      slug: 'ahmad-g12-physics',
      description: null,
      coverUrl: null,
    ),
  ],
);

RemoteConfig configWith({required bool teacherFollowing}) => RemoteConfig(
  minSupportedVersion: const MinSupportedVersion(android: '1.0.0', ios: '1.0.0', web: '1.0.0'),
  latestVersion: const LatestVersion(android: '1.0.0', ios: '1.0.0', web: '1.0.0'),
  features: Features(
    teacherFollowing: teacherFollowing,
    randomPractice: true,
    studentDecks: true,
    streaks: true,
    contentReports: true,
  ),
  srsDefaults: const SrsDefaults(newCardsPerDay: 20, maxReviewsPerDay: 200),
  support: const Support(email: '', whatsapp: ''),
  privacyPolicyUrl: '',
  termsUrl: '',
);

Future<void> openTeacher(WidgetTester tester) async {
  await tester.tap(find.text('المواد').last);
  await tester.pumpAndSettle();
  await tester.tap(fieldByKey('subjects.teachers'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('أ. أحمد'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('teachers list → profile with bio and tracks → follow', (tester) async {
    var following = false;
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeTeachers: (t) {
        when(() => t.teachers()).thenAnswer((_) async => [teacher()]);
        when(
          () => t.profile('t1'),
        ).thenAnswer((_) async => profile(following: following, followers: following ? 1 : 0));
        when(() => t.setFollowing('t1', any())).thenAnswer((inv) async {
          following = inv.positionalArguments[1] as bool;
          return FollowResult(following: following, followerCount: following ? 1 : 0);
        });
      },
    );
    await openTeacher(tester);

    expect(find.byType(TeacherScreen), findsOneWidget);
    expect(find.text('خبرة عشرين عاماً في تدريس الفيزياء'), findsOneWidget);
    expect(find.text('أ. أحمد — فيزياء بكالوريا'), findsOneWidget);
    expect(find.text('لا متابعين بعد'), findsOneWidget);

    await tester.tap(fieldByKey('teacher.follow'));
    await tester.pumpAndSettle();
    verify(() => app.teachers.setFollowing('t1', true)).called(1);
    expect(fieldByKey('teacher.unfollow'), findsOneWidget);
    expect(find.text('متابع واحد'), findsOneWidget);

    await tester.tap(fieldByKey('teacher.unfollow'));
    await tester.pumpAndSettle();
    verify(() => app.teachers.setFollowing('t1', false)).called(1);
    expect(fieldByKey('teacher.follow'), findsOneWidget);
  });

  testWidgets('the remote teacherFollowing flag hides following', (tester) async {
    await pumpApp(
      tester,
      signedInAs: testMe,
      config: configWith(teacherFollowing: false),
      arrangeTeachers: (t) {
        when(() => t.teachers()).thenAnswer((_) async => [teacher()]);
        when(() => t.profile('t1')).thenAnswer((_) async => profile());
      },
    );
    await openTeacher(tester);
    expect(fieldByKey('teacher.follow'), findsNothing);
    expect(find.text('أ. أحمد — فيزياء بكالوريا'), findsOneWidget);
  });

  testWidgets('a track opens its page with teacher and subject links', (tester) async {
    await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeTeachers: (t) {
        when(() => t.teachers()).thenAnswer((_) async => [teacher()]);
        when(() => t.profile('t1')).thenAnswer((_) async => profile());
        when(() => t.track('tr1')).thenAnswer(
          (_) async => TrackDetail(
            track: profile().tracks.first,
            teacher: teacher(),
            subject: subject('p', 'الفيزياء'),
            access: noAccess,
          ),
        );
      },
    );
    await openTeacher(tester);
    await tester.tap(find.text('أ. أحمد — فيزياء بكالوريا'));
    await tester.pumpAndSettle();
    expect(find.byType(TrackScreen), findsOneWidget);
    expect(find.text('المدرس'), findsOneWidget);
    expect(find.text('المادة'), findsOneWidget);
    expect(find.text('محتوى هذا المسار قيد الإعداد'), findsOneWidget);
  });

  test('follower counts follow Arabic number agreement', () {
    expect([0, 1, 2, 5, 11].map(followersLabel), [
      'لا متابعين بعد',
      'متابع واحد',
      'متابعان',
      '5 متابعين',
      '11 متابعاً',
    ]);
  });
}
