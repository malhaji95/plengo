// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/student_quiz_envelope.dart';
import '../models/student_quiz_list_envelope.dart';

part 'quizzes_client.g.dart';

@RestApi()
abstract class QuizzesClient {
  factory QuizzesClient(Dio dio, {String? baseUrl}) = _QuizzesClient;

  @GET('/api/v1/quizzes')
  Future<StudentQuizListEnvelope> listQuizzes({
    @Query('subjectId') required String subjectId,
    @Query('teacherTrackId') String? teacherTrackId,
    @Query('unitId') String? unitId,
    @Query('lessonId') String? lessonId,
  });

  @GET('/api/v1/quizzes/{id}')
  Future<StudentQuizEnvelope> getQuiz({
    @Path('id') required String id,
  });
}
