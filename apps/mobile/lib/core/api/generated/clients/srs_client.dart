// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/due_cards_envelope.dart';
import '../models/srs_states_page_envelope.dart';
import '../models/srs_sync_request.dart';
import '../models/srs_sync_result_envelope.dart';

part 'srs_client.g.dart';

@RestApi()
abstract class SrsClient {
  factory SrsClient(Dio dio, {String? baseUrl}) = _SrsClient;

  @GET('/api/v1/srs/states')
  Future<SrsStatesPageEnvelope> listSrsStates({
    @Query('limit') int? limit = 500,
    @Query('since') String? since,
  });

  @POST('/api/v1/srs/sync')
  Future<SrsSyncResultEnvelope> syncSrs({
    @Body() required SrsSyncRequest body,
  });

  @GET('/api/v1/srs/due')
  Future<DueCardsEnvelope> listDueCards({
    @Query('subjectId') String? subjectId,
  });
}
