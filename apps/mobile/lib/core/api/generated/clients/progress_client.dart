// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/resume_list_envelope.dart';
import '../models/scope_progress_envelope.dart';

part 'progress_client.g.dart';

@RestApi()
abstract class ProgressClient {
  factory ProgressClient(Dio dio, {String? baseUrl}) = _ProgressClient;

  @GET('/api/v1/progress')
  Future<ScopeProgressEnvelope> getProgress({
    @Query('subjectId') required String subjectId,
    @Query('teacherTrackId') String? teacherTrackId,
  });

  @GET('/api/v1/progress/resume')
  Future<ResumeListEnvelope> getResume();
}
