// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/flashcard_stats_envelope.dart';
import '../models/stats_overview_envelope.dart';
import '../models/stats_trend_envelope.dart';
import '../models/subject_stats_envelope.dart';

part 'stats_client.g.dart';

@RestApi()
abstract class StatsClient {
  factory StatsClient(Dio dio, {String? baseUrl}) = _StatsClient;

  @GET('/api/v1/stats/overview')
  Future<StatsOverviewEnvelope> getStatsOverview();

  @GET('/api/v1/stats/subjects/{id}')
  Future<SubjectStatsEnvelope> getSubjectStats({@Path('id') required String id});

  @GET('/api/v1/stats/trend')
  Future<StatsTrendEnvelope> getStatsTrend({@Query('weeks') int? weeks = 12});

  @GET('/api/v1/stats/flashcards')
  Future<FlashcardStatsEnvelope> getFlashcardStats();
}
