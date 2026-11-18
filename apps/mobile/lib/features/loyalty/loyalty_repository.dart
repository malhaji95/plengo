import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';

/// Loyalty points (V3_PLAN §10): balance and today's cap, rewards to redeem, the history.
class LoyaltyRepository {
  LoyaltyRepository(this.client);

  final ApiClient client;

  Future<LoyaltySummary> summary() => guardApi(() async => (await client.api.loyalty.getLoyaltySummary()).data);

  Future<List<LoyaltyLedgerEntry>> history() =>
      guardApi(() async => (await client.api.loyalty.listLoyaltyHistory()).data.items);

  Future<LoyaltyRewardList> rewards() => guardApi(() async => (await client.api.loyalty.listLoyaltyRewards()).data);

  /// Errors: INSUFFICIENT_POINTS, ALREADY_ENTITLED (an [ApiException] with the Arabic message).
  Future<LoyaltyRedeemResult> redeem(String rewardId) =>
      guardApi(() async => (await client.api.loyalty.redeemLoyaltyReward(id: rewardId)).data);

  Future<List<LoyaltyRedemption>> redemptions() =>
      guardApi(() async => (await client.api.loyalty.listMyLoyaltyRedemptions()).data);
}

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) => LoyaltyRepository(ref.watch(apiClientProvider)));

/// Kept alive: the Home chip and the drawer read it. Refreshed after a redeem and when Home reloads.
final loyaltySummaryProvider = FutureProvider<LoyaltySummary>((ref) => ref.watch(loyaltyRepositoryProvider).summary());

/// Whether loyalty is on; false while loading, offline or disabled (everything loyalty hides then).
final loyaltyEnabledProvider = Provider<bool>((ref) => ref.watch(loyaltySummaryProvider).value?.enabled ?? false);

final loyaltyRewardsProvider = FutureProvider.autoDispose<LoyaltyRewardList>(
  (ref) => ref.watch(loyaltyRepositoryProvider).rewards(),
);

final loyaltyHistoryProvider = FutureProvider.autoDispose<List<LoyaltyLedgerEntry>>(
  (ref) => ref.watch(loyaltyRepositoryProvider).history(),
);

final loyaltyRedemptionsProvider = FutureProvider.autoDispose<List<LoyaltyRedemption>>(
  (ref) => ref.watch(loyaltyRepositoryProvider).redemptions(),
);
