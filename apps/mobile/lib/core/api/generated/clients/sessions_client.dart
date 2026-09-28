// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/revoked_result_envelope.dart';
import '../models/session_list_envelope.dart';

part 'sessions_client.g.dart';

@RestApi()
abstract class SessionsClient {
  factory SessionsClient(Dio dio, {String? baseUrl}) = _SessionsClient;

  @GET('/api/v1/sessions')
  Future<SessionListEnvelope> listSessions();

  @DELETE('/api/v1/sessions/{id}')
  Future<RevokedResultEnvelope> revokeSession({@Path('id') required String id});
}
