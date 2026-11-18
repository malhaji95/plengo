// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/admin_loyalty_redemption_page_envelope.dart';
import '../models/admin_loyalty_reward_envelope.dart';
import '../models/admin_loyalty_reward_list_envelope.dart';
import '../models/admin_student_loyalty_envelope.dart';
import '../models/create_loyalty_reward_request.dart';
import '../models/deleted_result_envelope.dart';
import '../models/loyalty_adjust_request.dart';
import '../models/loyalty_redemption_envelope.dart';
import '../models/loyalty_redemption_status.dart';
import '../models/loyalty_settings.dart';
import '../models/loyalty_settings_envelope.dart';
import '../models/redemption_status_request.dart';
import '../models/update_loyalty_reward_request.dart';

part 'admin_loyalty_client.g.dart';

@RestApi()
abstract class AdminLoyaltyClient {
  factory AdminLoyaltyClient(Dio dio, {String? baseUrl}) = _AdminLoyaltyClient;

  @GET('/api/v1/admin/settings/loyalty')
  Future<LoyaltySettingsEnvelope> adminGetLoyaltySettings();

  @PUT('/api/v1/admin/settings/loyalty')
  Future<LoyaltySettingsEnvelope> adminUpdateLoyaltySettings({
    @Body() required LoyaltySettings body,
  });

  @GET('/api/v1/admin/loyalty/rewards')
  Future<AdminLoyaltyRewardListEnvelope> adminListLoyaltyRewards();

  @POST('/api/v1/admin/loyalty/rewards')
  Future<AdminLoyaltyRewardEnvelope> adminCreateLoyaltyReward({
    @Body() required CreateLoyaltyRewardRequest body,
  });

  @PATCH('/api/v1/admin/loyalty/rewards/{id}')
  Future<AdminLoyaltyRewardEnvelope> adminUpdateLoyaltyReward({
    @Path('id') required String id,
    @Body() required UpdateLoyaltyRewardRequest body,
  });

  @DELETE('/api/v1/admin/loyalty/rewards/{id}')
  Future<DeletedResultEnvelope> adminDeleteLoyaltyReward({
    @Path('id') required String id,
  });

  @GET('/api/v1/admin/loyalty/redemptions')
  Future<AdminLoyaltyRedemptionPageEnvelope> adminListLoyaltyRedemptions({
    @Query('limit') int? limit = 50,
    @Query('status') LoyaltyRedemptionStatus? status,
    @Query('userId') String? userId,
    @Query('cursor') String? cursor,
  });

  /// `fulfilled` marks a custom reward handed over; `cancelled` refunds the points.
  @POST('/api/v1/admin/loyalty/redemptions/{id}/status')
  Future<LoyaltyRedemptionEnvelope> adminSetLoyaltyRedemptionStatus({
    @Path('id') required String id,
    @Body() required RedemptionStatusRequest body,
  });

  @GET('/api/v1/admin/students/{id}/loyalty')
  Future<AdminStudentLoyaltyEnvelope> adminGetStudentLoyalty({
    @Path('id') required String id,
  });

  @POST('/api/v1/admin/students/{id}/loyalty/adjust')
  Future<AdminStudentLoyaltyEnvelope> adminAdjustStudentLoyalty({
    @Path('id') required String id,
    @Body() required LoyaltyAdjustRequest body,
  });
}
