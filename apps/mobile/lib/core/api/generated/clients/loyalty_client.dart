// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/loyalty_ledger_page_envelope.dart';
import '../models/loyalty_redeem_result_envelope.dart';
import '../models/loyalty_redemption_list_envelope.dart';
import '../models/loyalty_reward_list_envelope.dart';
import '../models/loyalty_summary_envelope.dart';

part 'loyalty_client.g.dart';

@RestApi()
abstract class LoyaltyClient {
  factory LoyaltyClient(Dio dio, {String? baseUrl}) = _LoyaltyClient;

  /// Balance, points earned today toward the daily cap, and the current rules.
  @GET('/api/v1/loyalty')
  Future<LoyaltySummaryEnvelope> getLoyaltySummary();

  /// The latest 100 point changes, newest first.
  @GET('/api/v1/loyalty/history')
  Future<LoyaltyLedgerPageEnvelope> listLoyaltyHistory();

  @GET('/api/v1/loyalty/rewards')
  Future<LoyaltyRewardListEnvelope> listLoyaltyRewards();

  /// Spends points. `unlock_deck` opens the deck at once (ALREADY_ENTITLED if it is already open); `custom` is recorded for the admin. INSUFFICIENT_POINTS when the balance is short.
  @POST('/api/v1/loyalty/rewards/{id}/redeem')
  Future<LoyaltyRedeemResultEnvelope> redeemLoyaltyReward({
    @Path('id') required String id,
  });

  @GET('/api/v1/loyalty/redemptions')
  Future<LoyaltyRedemptionListEnvelope> listMyLoyaltyRedemptions();
}
