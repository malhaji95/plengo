import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/app.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/core/access/access_repository.dart';
import 'package:plengo/core/auth/auth_repository.dart';
import 'package:plengo/core/auth/token_store.dart';
import 'package:plengo/core/catalog/catalog_repository.dart';
import 'package:plengo/core/catalog/teacher_repository.dart';
import 'package:plengo/core/content/flashcard_repository.dart';
import 'package:plengo/core/content/question_repository.dart';
import 'package:plengo/core/db/app_database.dart';
import 'package:plengo/core/learning/learning_repository.dart';
import 'package:plengo/core/srs/srs_store.dart';
import 'package:plengo/features/access/access_providers.dart';
import 'package:plengo/features/flashcards/card_face.dart';
import 'package:plengo/features/flashcards/flashcard_providers.dart';
import 'package:plengo/features/questions/question_providers.dart';
import 'package:plengo/features/quizzes/quiz_providers.dart';
import 'package:plengo/features/subjects/catalog_providers.dart';
import 'package:plengo/features/teachers/teacher_providers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockTeacherRepository extends Mock implements TeacherRepository {}

class MockAccessRepository extends Mock implements AccessRepository {}

class MockQuestionRepository extends Mock implements QuestionRepository {}

class MockFlashcardRepository extends Mock implements FlashcardRepository {}

class MockLearningRepository extends Mock implements LearningRepository {}

const noQuestions = ContentCount(total: 0, free: 0);

ScopeProgress emptyProgress(String subjectId, {String? teacherTrackId}) => ScopeProgress(
  questionsAttempted: 0,
  questionsCorrect: 0,
  questionsTotal: 0,
  quizzesCompleted: 0,
  quizzesTotal: 0,
  flashcardsStudied: 0,
  flashcardsTotal: 0,
  completionPercent: 0,
  subjectId: subjectId,
  teacherTrackId: teacherTrackId,
  lastActivityAt: null,
  units: const [],
  lessons: const [],
);

const noAccess = ScopeAccess(
  hasAccess: false,
  reason: null,
  isPermanent: false,
  entitlementExpiresAt: null,
  promotionTitleAr: null,
  promotionEndsAt: null,
);

const grade9 = EducationLevel(id: 'l9', code: 'grade-9', nameAr: 'الصف التاسع', sortOrder: 1, isCollege: false);
const grade12 = EducationLevel(id: 'l12', code: 'grade-12', nameAr: 'البكالوريا', sortOrder: 2, isCollege: false);
const college = EducationLevel(id: 'lc', code: 'college', nameAr: 'الجامعة', sortOrder: 3, isCollege: true);

const testMe = Me(
  id: 'u1',
  email: 'student@example.com',
  emailVerified: true,
  role: MeRole.student,
  fullName: 'سارة أحمد',
  educationLevelId: 'l12',
  universityId: null,
  facultyId: null,
  academicYearId: null,
);

Subject subject(String id, String name, {String levelId = 'l12', String? description}) => Subject(
  id: id,
  educationLevelId: levelId,
  universityId: null,
  facultyId: null,
  academicYearId: null,
  code: id,
  nameAr: name,
  description: description,
  coverMediaId: null,
  coverUrl: null,
  sortOrder: 0,
  isActive: true,
);

typedef PumpedApp = ({
  MockAuthRepository repo,
  MockCatalogRepository catalog,
  MockTeacherRepository teachers,
  MockAccessRepository access,
  MockQuestionRepository questions,
  MockFlashcardRepository flashcards,
  MockLearningRepository learning,
  AppDatabase db,
  ProviderContainer container,
});

/// Pumps the real app with mocked repositories and an in-memory database. The config call made
/// at start-up goes nowhere (no server); it is designed to fail silently.
Future<PumpedApp> pumpApp(
  WidgetTester tester, {
  Me? signedInAs,
  void Function(MockAuthRepository repo)? arrange,
  void Function(MockCatalogRepository catalog)? arrangeCatalog,
  void Function(MockTeacherRepository teachers)? arrangeTeachers,
  void Function(MockAccessRepository access)? arrangeAccess,
  void Function(MockQuestionRepository questions)? arrangeQuestions,
  void Function(MockFlashcardRepository flashcards)? arrangeFlashcards,
  void Function(MockLearningRepository learning)? arrangeLearning,
  int Function()? clock,
  RemoteConfig? config,
  bool couponRedemption = true,
}) async {
  registerFallbacks();
  final repo = MockAuthRepository();
  when(() => repo.restoreSession()).thenAnswer((_) async => signedInAs);
  arrange?.call(repo);

  final catalog = MockCatalogRepository();
  when(() => catalog.levels()).thenAnswer((_) async => const [grade9, grade12, college]);
  when(() => catalog.universities()).thenAnswer((_) async => const []);
  when(() => catalog.subjects(any())).thenAnswer((_) async => const []);
  arrangeCatalog?.call(catalog);

  final teachers = MockTeacherRepository();
  when(() => teachers.teachers()).thenAnswer((_) async => const []);
  when(() => teachers.followed()).thenAnswer((_) async => const []);
  arrangeTeachers?.call(teachers);

  final access = MockAccessRepository();
  when(() => access.myEntitlements()).thenAnswer((_) async => const []);
  arrangeAccess?.call(access);

  final questions = MockQuestionRepository();
  arrangeQuestions?.call(questions);

  final flashcards = MockFlashcardRepository();
  when(() => flashcards.push(any())).thenAnswer((_) async => 0);
  when(() => flashcards.pull(any())).thenAnswer((_) async {});
  arrangeFlashcards?.call(flashcards);

  final learning = MockLearningRepository();
  when(() => learning.resume()).thenAnswer((_) async => const []);
  when(() => learning.bookmarkKeys()).thenAnswer((_) async => const []);
  when(
    () => learning.progress(any(), teacherTrackId: any(named: 'teacherTrackId')),
  ).thenAnswer((i) async => emptyProgress(i.positionalArguments.first as String));
  arrangeLearning?.call(learning);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [
      appEnvironmentProvider.overrideWithValue(const AppEnvironment(platform: 'android', appVersion: '1.0.0')),
      tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
      databaseProvider.overrideWithValue(db),
      authRepositoryProvider.overrideWithValue(repo),
      catalogRepositoryProvider.overrideWithValue(catalog),
      teacherRepositoryProvider.overrideWithValue(teachers),
      accessRepositoryProvider.overrideWithValue(access),
      questionRepositoryProvider.overrideWithValue(questions),
      flashcardRepositoryProvider.overrideWithValue(flashcards),
      learningRepositoryProvider.overrideWithValue(learning),
      cardImageBuilderProvider.overrideWithValue((_, image) => Center(child: Text('img:${image.mediaId}'))),
      cardImagePrefetchProvider.overrideWithValue((_, _) {}),
      if (clock != null) clockProvider.overrideWithValue(clock),
      couponRedemptionProvider.overrideWithValue(couponRedemption),
      remoteConfigProvider.overrideWith((ref) async => config),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const PlengoApp()));
  await tester.pumpAndSettle();
  return (
    repo: repo,
    catalog: catalog,
    teachers: teachers,
    access: access,
    questions: questions,
    flashcards: flashcards,
    learning: learning,
    db: db,
    container: container,
  );
}

void registerFallbacks() {
  registerFallbackValue((levelId: '', universityId: null, facultyId: null, academicYearId: null));
  registerFallbackValue((subjectId: '', teacherTrackId: null, unitId: null, lessonId: null));
  registerFallbackValue(SrsStore(AppDatabase(NativeDatabase.memory())));
}

Finder fieldByKey(String key) => find.byKey(Key(key));
