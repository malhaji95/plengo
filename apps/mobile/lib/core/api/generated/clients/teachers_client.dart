// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/follow_result_envelope.dart';
import '../models/teacher_list_envelope.dart';
import '../models/teacher_profile_envelope.dart';
import '../models/track_detail_envelope.dart';

part 'teachers_client.g.dart';

@RestApi()
abstract class TeachersClient {
  factory TeachersClient(Dio dio, {String? baseUrl}) = _TeachersClient;

  @GET('/api/v1/teachers')
  Future<TeacherListEnvelope> listTeachers();

  @GET('/api/v1/teachers/following')
  Future<TeacherListEnvelope> listFollowedTeachers();

  @GET('/api/v1/teachers/{id}')
  Future<TeacherProfileEnvelope> getTeacherProfile({
    @Path('id') required String id,
  });

  @PUT('/api/v1/teachers/{id}/follow')
  Future<FollowResultEnvelope> followTeacher({
    @Path('id') required String id,
  });

  @DELETE('/api/v1/teachers/{id}/follow')
  Future<FollowResultEnvelope> unfollowTeacher({
    @Path('id') required String id,
  });

  @GET('/api/v1/teacher-tracks/{id}')
  Future<TrackDetailEnvelope> getTrack({
    @Path('id') required String id,
  });
}
