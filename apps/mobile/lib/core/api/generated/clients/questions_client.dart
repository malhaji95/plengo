// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/check_answer_request.dart';
import '../models/check_result_envelope.dart';
import '../models/student_question_envelope.dart';
import '../models/student_question_page_envelope.dart';

part 'questions_client.g.dart';

@RestApi()
abstract class QuestionsClient {
  factory QuestionsClient(Dio dio, {String? baseUrl}) = _QuestionsClient;

  @GET('/api/v1/questions')
  Future<StudentQuestionPageEnvelope> listQuestions({
    @Query('subjectId') required String subjectId,
    @Query('limit') int? limit = 30,
    @Query('teacherTrackId') String? teacherTrackId,
    @Query('unitId') String? unitId,
    @Query('lessonId') String? lessonId,
    @Query('cursor') String? cursor,
  });

  @GET('/api/v1/questions/{id}')
  Future<StudentQuestionEnvelope> getQuestion({@Path('id') required String id});

  @POST('/api/v1/questions/{id}/check')
  Future<CheckResultEnvelope> checkQuestionAnswer({
    @Path('id') required String id,
    @Body() required CheckAnswerRequest body,
  });
}
