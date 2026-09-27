import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flags.dart';
import '../../app/providers.dart';
import '../../core/access/access_repository.dart';
import '../../core/api/generated/export.dart';
import '../subjects/catalog_providers.dart';
import '../teachers/teacher_providers.dart';

final accessRepositoryProvider = Provider<AccessRepository>((ref) => AccessRepository(ref.watch(apiClientProvider)));

/// The compile-time COUPON_REDEMPTION flag (spec §10.1). Exposed as a provider only so tests can
/// build both variants; nothing remote may ever override it.
final couponRedemptionProvider = Provider<bool>((ref) => AppFlags.couponRedemption);

final myEntitlementsProvider = FutureProvider.autoDispose<List<MyEntitlement>>(
  (ref) => ref.watch(accessRepositoryProvider).myEntitlements(),
);

/// Redeems a code, then refreshes every view that shows access state.
Future<RedeemResult> redeemCoupon(WidgetRef ref, String code) async {
  final result = await ref.read(accessRepositoryProvider).redeem(code);
  ref
    ..invalidate(myEntitlementsProvider)
    ..invalidate(subjectOutlineProvider)
    ..invalidate(trackProvider);
  return result;
}
