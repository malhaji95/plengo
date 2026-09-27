import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plengo/app/router.dart';

final _routerWithCoupons = Provider<GoRouter>((ref) => buildRouter(ref, couponRedemption: true));
final _routerWithoutCoupons = Provider<GoRouter>((ref) => buildRouter(ref, couponRedemption: false));

bool hasRoute(GoRouter router, String path) =>
    router.configuration.routes.whereType<GoRoute>().any((r) => r.path == path);

void main() {
  test('the coupon redemption route exists only when the compile-time flag is on (spec §37.5)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(hasRoute(container.read(_routerWithCoupons), Routes.redeem), isTrue);
    expect(hasRoute(container.read(_routerWithoutCoupons), Routes.redeem), isFalse);
  });
}
