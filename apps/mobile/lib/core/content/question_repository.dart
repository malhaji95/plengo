import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';

/// Which questions to list: a subject's general content, or one track, optionally one unit/lesson.
typedef QuestionQuery = ({String subjectId, String? teacherTrackId, String? unitId, String? lessonId});

/// Published questions (spec §14). The server never sends correctness before grading.
class QuestionRepository {
  QuestionRepository(this.client);

  final ApiClient client;

  /// [categoryIds]: comma-separated category ids (a parent includes its children, v3 §3).
  Future<StudentQuestionPage> page(QuestionQuery q, {String? cursor, String? categoryIds}) => guardApi(
    () async => (await client.api.questions.listQuestions(
      subjectId: q.subjectId,
      teacherTrackId: q.teacherTrackId,
      unitId: q.unitId,
      lessonId: q.lessonId,
      categoryIds: categoryIds,
      cursor: cursor,
    )).data,
  );

  /// The question categories of a subject with published counts for the scope, unit or lesson (v3 §3, §5).
  Future<StudentQuestionCategoryList> categories(QuestionQuery q) => guardApi(
    () async => (await client.api.questions.listQuestionCategories(
      subjectId: q.subjectId,
      teacherTrackId: q.teacherTrackId,
      unitId: q.unitId,
      lessonId: q.lessonId,
    )).data,
  );

  Future<CheckResult> check(String questionId, {String? selectedOptionId, String? writtenAnswer}) => guardApi(
    () async => (await client.api.questions.checkQuestionAnswer(
      id: questionId,
      body: CheckAnswerRequest(selectedOptionId: selectedOptionId, writtenAnswer: writtenAnswer),
    )).data,
  );
}
