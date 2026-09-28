// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/goal_settings.dart';
import '../models/goal_settings_envelope.dart';
import '../models/home_envelope.dart';

part 'home_client.g.dart';

@RestApi()
abstract class HomeClient {
  factory HomeClient(Dio dio, {String? baseUrl}) = _HomeClient;

  @GET('/api/v1/home')
  Future<HomeEnvelope> getHome();

  @GET('/api/v1/me/settings')
  Future<GoalSettingsEnvelope> getGoalSettings();

  @PUT('/api/v1/me/settings')
  Future<GoalSettingsEnvelope> updateGoalSettings({@Body() required GoalSettings body});
}
