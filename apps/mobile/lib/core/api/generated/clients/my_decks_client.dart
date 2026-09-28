// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/user_content_changes_envelope.dart';
import '../models/user_content_sync_request.dart';
import '../models/user_content_sync_result_envelope.dart';
import '../models/user_deck_cards_envelope.dart';
import '../models/user_deck_list_envelope.dart';

part 'my_decks_client.g.dart';

@RestApi()
abstract class MyDecksClient {
  factory MyDecksClient(Dio dio, {String? baseUrl}) = _MyDecksClient;

  @GET('/api/v1/my-decks')
  Future<UserDeckListEnvelope> listMyDecks();

  @GET('/api/v1/my-decks/changes')
  Future<UserContentChangesEnvelope> myDeckChanges({@Query('limit') int? limit = 500, @Query('since') String? since});

  @POST('/api/v1/my-decks/sync')
  Future<UserContentSyncResultEnvelope> syncMyDecks({@Body() required UserContentSyncRequest body});

  @GET('/api/v1/my-decks/{id}/cards')
  Future<UserDeckCardsEnvelope> getMyDeckCards({@Path('id') required String id});
}
