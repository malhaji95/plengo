import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';

/// "My access" and coupon redemption (spec §9.4, §23.2 #27–28). The server decides everything;
/// the app only shows the result.
class AccessRepository {
  AccessRepository(this.client);

  final ApiClient client;

  Future<List<MyEntitlement>> myEntitlements() =>
      guardApi(() async => (await client.api.access.listMyEntitlements()).data);

  Future<RedeemResult> redeem(String code) =>
      guardApi(() async => (await client.api.access.redeemCoupon(body: RedeemCouponRequest(code: code))).data);
}
