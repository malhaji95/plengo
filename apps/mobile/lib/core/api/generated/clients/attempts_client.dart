// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/attempt_envelope.dart';
import '../models/attempt_status.dart';
import '../models/attempt_summary_page_envelope.dart';
import '../models/check_attempt_answer_request.dart';
import '../models/check_result_envelope.dart';
import '../models/save_answer_request.dart';
import '../models/saved_answer_envelope.dart';
import '../models/start_attempt_request.dart';
import '../models/submit_attempt_request.dart';

part 'attempts_client.g.dart';

@RestApi()
abstract class AttemptsClient {
  factory AttemptsClient(Dio dio, {String? baseUrl}) = _AttemptsClient;

  @POST('/api/v1/attempts')
  Future<AttemptEnvelope> startAttempt({@Body() required StartAttemptRequest body});

  @GET('/api/v1/attempts')
  Future<AttemptSummaryPageEnvelope> listAttempts({
    @Query('limit') int? limit = 20,
    @Query('status') AttemptStatus? status,
    @Query('quizId') String? quizId,
    @Query('cursor') String? cursor,
  });

  @GET('/api/v1/attempts/{id}')
  Future<AttemptEnvelope> getAttempt({@Path('id') required String id});

  @PUT('/api/v1/attempts/{id}/answers/{questionId}')
  Future<SavedAnswerEnvelope> saveAttemptAnswer({
    @Path('id') required String id,
    @Path('questionId') required String questionId,
    @Body() required SaveAnswerRequest body,
  });

  @POST('/api/v1/attempts/{id}/answers/{questionId}/check')
  Future<CheckResultEnvelope> checkAttemptAnswer({
    @Path('id') required String id,
    @Path('questionId') required String questionId,
    @Body() required CheckAttemptAnswerRequest body,
  });

  @POST('/api/v1/attempts/{id}/submit')
  Future<AttemptEnvelope> submitAttempt({@Path('id') required String id, @Body() required SubmitAttemptRequest body});
}
