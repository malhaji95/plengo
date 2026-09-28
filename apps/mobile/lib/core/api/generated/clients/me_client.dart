// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/deleted_result_envelope.dart';
import '../models/me_envelope.dart';
import '../models/password_confirm_request.dart';
import '../models/update_profile_request.dart';

part 'me_client.g.dart';

@RestApi()
abstract class MeClient {
  factory MeClient(Dio dio, {String? baseUrl}) = _MeClient;

  @GET('/api/v1/me')
  Future<MeEnvelope> getMe();

  @PATCH('/api/v1/me')
  Future<MeEnvelope> updateMe({@Body() required UpdateProfileRequest body});

  /// Deletes the account after the password is confirmed (spec §33): personal data, sessions, access and student decks go; learning history stays anonymous.
  @POST('/api/v1/me/delete')
  Future<DeletedResultEnvelope> deleteMyAccount({@Body() required PasswordConfirmRequest body});
}
