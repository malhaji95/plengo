import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import 'access_format.dart';
import 'access_providers.dart';

/// A scope's access state at the top of a subject or track page (spec §8.6, §8.7).
class ScopeAccessBanner extends StatelessWidget {
  const ScopeAccessBanner({super.key, required this.access});

  final ScopeAccess access;

  @override
  Widget build(BuildContext context) {
    if (!access.hasAccess) return const LockedNotice();
    final scheme = Theme.of(context).colorScheme;
    final promotion = access.reason == ScopeAccessReason.promotion;
    final text = promotion
        ? 'متاح مجاناً ضمن «${access.promotionTitleAr ?? 'عرض'}» حتى ${damascusDate(access.promotionEndsAt!)}'
        : access.isPermanent
        ? 'لديك وصول دائم إلى هذا المحتوى'
        : 'لديك وصول إلى هذا المحتوى حتى ${damascusDate(access.entitlementExpiresAt!)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: scheme.secondaryContainer,
      child: ListTile(
        leading: Icon(promotion ? Icons.celebration_outlined : Icons.lock_open, color: scheme.onSecondaryContainer),
        title: Text(text, style: TextStyle(color: scheme.onSecondaryContainer)),
      ),
    );
  }
}

/// spec §8.7: with COUPON_REDEMPTION the student is offered the code screen; without it the app only
/// says the content is unavailable, with no button and no route to reach redemption.
class LockedNotice extends ConsumerWidget {
  const LockedNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final redeem = ref.watch(couponRedemptionProvider);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    redeem ? 'هذا المحتوى يحتاج إلى تفعيل' : 'هذا المحتوى غير متاح على حسابك',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            if (redeem) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.push(Routes.redeem),
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('إدخال كود التفعيل'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
