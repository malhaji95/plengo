import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';

/// Which quizzes to list: a subject's general content, or one track, optionally one unit/lesson.
typedef QuizQuery = ({String subjectId, String? teacherTrackId, String? unitId, String? lessonId});

/// Quizzes, attempts, mistake bank, statistics, bookmarks and progress (spec §15–§18).
class LearningRepository {
  LearningRepository(this.client);

  final ApiClient client;

  Future<List<StudentQuiz>> quizzes(QuizQuery q) => guardApi(
    () async => (await client.api.quizzes.listQuizzes(
      subjectId: q.subjectId,
      teacherTrackId: q.teacherTrackId,
      unitId: q.unitId,
      lessonId: q.lessonId,
    )).data,
  );

  Future<StudentQuiz> quiz(String id) => guardApi(() async => (await client.api.quizzes.getQuiz(id: id)).data);

  Future<Attempt> start(StartAttemptRequest body) =>
      guardApi(() async => (await client.api.attempts.startAttempt(body: body)).data);

  Future<Attempt> attempt(String id) => guardApi(() async => (await client.api.attempts.getAttempt(id: id)).data);

  Future<AttemptSummaryPage> attempts({String? quizId, AttemptStatus? status}) =>
      guardApi(() async => (await client.api.attempts.listAttempts(quizId: quizId, status: status)).data);

  Future<SavedAnswer> save(String attemptId, String questionId, SaveAnswerRequest body) => guardApi(
    () async => (await client.api.attempts.saveAttemptAnswer(id: attemptId, questionId: questionId, body: body)).data,
  );

  Future<CheckResult> check(String attemptId, String questionId, CheckAttemptAnswerRequest body) => guardApi(
    () async => (await client.api.attempts.checkAttemptAnswer(id: attemptId, questionId: questionId, body: body)).data,
  );

  Future<Attempt> submit(String attemptId, SubmitAttemptRequest body) =>
      guardApi(() async => (await client.api.attempts.submitAttempt(id: attemptId, body: body)).data);

  Future<MistakeList> mistakes({MistakeFilterStatus status = MistakeFilterStatus.active}) =>
      guardApi(() async => (await client.api.mistakes.listMistakes(status: status)).data);

  Future<void> removeMistake(String questionId) =>
      guardApi(() async => client.api.mistakes.removeMistake(questionId: questionId));

  Future<StatsOverview> overview() => guardApi(() async => (await client.api.stats.getStatsOverview()).data);

  Future<SubjectStats> subjectStats(String id) =>
      guardApi(() async => (await client.api.stats.getSubjectStats(id: id)).data);

  Future<StatsTrend> trend({int weeks = 12}) =>
      guardApi(() async => (await client.api.stats.getStatsTrend(weeks: weeks)).data);

  Future<FlashcardStats> flashcardStats() => guardApi(() async => (await client.api.stats.getFlashcardStats()).data);

  Future<BookmarkList> bookmarks() => guardApi(() async => (await client.api.bookmarks.listBookmarks()).data);

  Future<List<BookmarkKey>> bookmarkKeys() =>
      guardApi(() async => (await client.api.bookmarks.listBookmarkKeys()).data);

  Future<void> addBookmark(BookmarkItemType type, String id) => guardApi(
    () async => client.api.bookmarks.addBookmark(
      body: BookmarkRequest(itemType: type, itemId: id),
    ),
  );

  Future<void> removeBookmark(BookmarkItemType type, String id) =>
      guardApi(() async => client.api.bookmarks.removeBookmark(itemType: type, itemId: id));

  Future<ScopeProgress> progress(String subjectId, {String? teacherTrackId}) => guardApi(
    () async => (await client.api.progress.getProgress(subjectId: subjectId, teacherTrackId: teacherTrackId)).data,
  );

  Future<List<ResumeItem>> resume() => guardApi(() async => (await client.api.progress.getResume()).data);
}
