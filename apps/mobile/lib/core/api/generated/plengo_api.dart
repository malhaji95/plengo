// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/config_client.dart';
import 'clients/structure_client.dart';
import 'clients/auth_client.dart';
import 'clients/me_client.dart';
import 'clients/sessions_client.dart';
import 'clients/uploads_client.dart';
import 'clients/teachers_client.dart';
import 'clients/access_client.dart';
import 'clients/questions_client.dart';
import 'clients/flashcards_client.dart';
import 'clients/srs_client.dart';
import 'clients/quizzes_client.dart';
import 'clients/attempts_client.dart';
import 'clients/mistakes_client.dart';
import 'clients/stats_client.dart';
import 'clients/bookmarks_client.dart';
import 'clients/progress_client.dart';

/// Plengo API `v1.0.0`
class PlengoApi {
  PlengoApi(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  ConfigClient? _config;
  StructureClient? _structure;
  AuthClient? _auth;
  MeClient? _me;
  SessionsClient? _sessions;
  UploadsClient? _uploads;
  TeachersClient? _teachers;
  AccessClient? _access;
  QuestionsClient? _questions;
  FlashcardsClient? _flashcards;
  SrsClient? _srs;
  QuizzesClient? _quizzes;
  AttemptsClient? _attempts;
  MistakesClient? _mistakes;
  StatsClient? _stats;
  BookmarksClient? _bookmarks;
  ProgressClient? _progress;

  ConfigClient get config => _config ??= ConfigClient(_dio, baseUrl: _baseUrl);

  StructureClient get structure => _structure ??= StructureClient(_dio, baseUrl: _baseUrl);

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  MeClient get me => _me ??= MeClient(_dio, baseUrl: _baseUrl);

  SessionsClient get sessions => _sessions ??= SessionsClient(_dio, baseUrl: _baseUrl);

  UploadsClient get uploads => _uploads ??= UploadsClient(_dio, baseUrl: _baseUrl);

  TeachersClient get teachers => _teachers ??= TeachersClient(_dio, baseUrl: _baseUrl);

  AccessClient get access => _access ??= AccessClient(_dio, baseUrl: _baseUrl);

  QuestionsClient get questions => _questions ??= QuestionsClient(_dio, baseUrl: _baseUrl);

  FlashcardsClient get flashcards => _flashcards ??= FlashcardsClient(_dio, baseUrl: _baseUrl);

  SrsClient get srs => _srs ??= SrsClient(_dio, baseUrl: _baseUrl);

  QuizzesClient get quizzes => _quizzes ??= QuizzesClient(_dio, baseUrl: _baseUrl);

  AttemptsClient get attempts => _attempts ??= AttemptsClient(_dio, baseUrl: _baseUrl);

  MistakesClient get mistakes => _mistakes ??= MistakesClient(_dio, baseUrl: _baseUrl);

  StatsClient get stats => _stats ??= StatsClient(_dio, baseUrl: _baseUrl);

  BookmarksClient get bookmarks => _bookmarks ??= BookmarksClient(_dio, baseUrl: _baseUrl);

  ProgressClient get progress => _progress ??= ProgressClient(_dio, baseUrl: _baseUrl);
}
