import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import 'access_format.dart';
import 'access_providers.dart';

/// A scope's access state at the top of a subject or track page (spec §8.6, §8.7): a green chip
/// («لديك وصول دائم…» / «حتى …» / «متاح مجاناً ضمن …»), or the [LockedNotice].
class ScopeAccessBanner extends StatelessWidget {
  const ScopeAccessBanner({super.key, required this.access, this.subjectId, this.teacherTrackId});

  final ScopeAccess access;

  /// The page's scope, handed to [LockedNotice] so the code screen knows where the student came from.
  final String? subjectId;
  final String? teacherTrackId;

  @override
  Widget build(BuildContext context) {
    if (!access.hasAccess) return LockedNotice(subjectId: subjectId, teacherTrackId: teacherTrackId);
    final promotion = access.reason == ScopeAccessReason.promotion;
    final text = promotion
        ? 'متاح مجاناً ضمن «${access.promotionTitleAr ?? 'عرض'}» حتى ${damascusDate(access.promotionEndsAt!)}'
        : access.isPermanent
        ? 'لديك وصول دائم إلى هذا المحتوى'
        : 'لديك وصول إلى هذا المحتوى حتى ${damascusDate(access.entitlementExpiresAt!)}';
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 14),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: PlengoChip(
          label: text,
          hue: PlengoColors.green,
          icon: promotion ? Icons.celebration_rounded : Icons.lock_open_rounded,
        ),
      ),
    );
  }
}

/// spec §8.7: with COUPON_REDEMPTION the student is offered the code screen; without it the app only
/// says the content is unavailable, with no button and no route to reach redemption. A red-soft box
/// with a lock icon and text, never colour alone.
///
/// [subjectId] / [teacherTrackId] are the locked content's scope. «إدخال كود التفعيل» opens the code
/// screen with them as `?subjectId=` / `?teacherTrackId=` so it can name the content and offer its
/// free lessons. Track content passes its track; the narrowest scope given wins.
class LockedNotice extends ConsumerWidget {
  const LockedNotice({super.key, this.subjectId, this.teacherTrackId});

  final String? subjectId;
  final String? teacherTrackId;

  /// The redeem route for this scope: the track when there is one, else the subject, else bare.
  String get redeemLocation {
    final query = teacherTrackId != null
        ? {'teacherTrackId': teacherTrackId!}
        : subjectId != null
        ? {'subjectId': subjectId!}
        : null;
    return Uri(path: Routes.redeem, queryParameters: query).toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final redeem = ref.watch(couponRedemptionProvider);
    final red = PlengoColors.red;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 14),
      child: PlengoCard(
        color: red.soft,
        radius: PlengoRadius.row,
        padding: const EdgeInsetsDirectional.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MergeSemantics(
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: red.fill,
                        borderRadius: BorderRadius.circular(PlengoRadius.iconTile),
                      ),
                      child: Icon(Icons.lock_rounded, color: red.onFill, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      redeem ? 'هذا المحتوى يحتاج إلى تفعيل' : 'هذا المحتوى غير متاح على حسابك',
                      style: PlengoType.rowTitle.copyWith(color: PlengoColors.ink, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            if (redeem) ...[
              const SizedBox(height: 12),
              PlengoButton(
                label: 'إدخال كود التفعيل',
                icon: Icons.vpn_key_rounded,
                size: PlengoButtonSize.small,
                expand: true,
                onPressed: () => context.push(redeemLocation),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
