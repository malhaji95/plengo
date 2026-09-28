// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/deck_cards_envelope.dart';
import '../models/student_deck_envelope.dart';
import '../models/student_deck_list_envelope.dart';

part 'flashcards_client.g.dart';

@RestApi()
abstract class FlashcardsClient {
  factory FlashcardsClient(Dio dio, {String? baseUrl}) = _FlashcardsClient;

  @GET('/api/v1/decks')
  Future<StudentDeckListEnvelope> listDecks({
    @Query('subjectId') required String subjectId,
    @Query('teacherTrackId') String? teacherTrackId,
    @Query('unitId') String? unitId,
    @Query('lessonId') String? lessonId,
  });

  @GET('/api/v1/decks/{id}')
  Future<StudentDeckEnvelope> getDeck({
    @Path('id') required String id,
  });

  @GET('/api/v1/decks/{id}/cards')
  Future<DeckCardsEnvelope> getDeckCards({
    @Path('id') required String id,
  });
}
