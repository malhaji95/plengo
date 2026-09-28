// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/deleted_result_envelope.dart';
import '../models/mistake_filter_status.dart';
import '../models/mistake_filter_type.dart';
import '../models/mistake_list_envelope.dart';

part 'mistakes_client.g.dart';

@RestApi()
abstract class MistakesClient {
  factory MistakesClient(Dio dio, {String? baseUrl}) = _MistakesClient;

  @GET('/api/v1/mistakes')
  Future<MistakeListEnvelope> listMistakes({
    @Query('limit') int? limit = 100,
    @Query('status') MistakeFilterStatus? status,
    @Query('subjectId') String? subjectId,
    @Query('teacherTrackId') String? teacherTrackId,
    @Query('unitId') String? unitId,
    @Query('lessonId') String? lessonId,
    @Query('type') MistakeFilterType? type,
    @Query('cursor') String? cursor,
  });

  @DELETE('/api/v1/mistakes/{questionId}')
  Future<DeletedResultEnvelope> removeMistake({@Path('questionId') required String questionId});
}
