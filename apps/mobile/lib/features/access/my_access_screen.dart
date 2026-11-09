import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import 'access_format.dart';
import 'access_providers.dart';

/// "My access" (spec §23.2 #28): active entitlements first, then expired and cancelled ones.
class MyAccessScreen extends ConsumerWidget {
  const MyAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlements = ref.watch(myEntitlementsProvider);
    final redeem = ref.watch(couponRedemptionProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const PlengoBackButton(),
        leadingWidth: kPlengoLeadingWidth,
        title: const Text('صلاحيات الوصول'),
      ),
      bottomNavigationBar: redeem
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 12),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: PlengoButton(
                      label: 'إدخال كود التفعيل',
                      icon: Icons.vpn_key_rounded,
                      variant: PlengoButtonVariant.brand,
                      onPressed: () => context.push(Routes.redeem),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: AsyncView(
        value: entitlements,
        onRetry: () => ref.invalidate(myEntitlementsProvider),
        data: (items) => items.isEmpty
            ? const EmptyState('لا توجد صلاحيات وصول بعد', icon: Icons.key_off_outlined)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(myEntitlementsProvider.future),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView.separated(
                      padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: PlengoSpace.listGap),
                      itemBuilder: (_, i) => _EntitlementRow(entitlement: items[i]),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _EntitlementRow extends StatelessWidget {
  const _EntitlementRow({required this.entitlement});

  final MyEntitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final e = entitlement;
    final s = context.surface;
    final active = e.state == MyEntitlementState.active;
    final isTrack = e.scope.scopeType == AccessScopeScopeType.teacherTrack;
    // State is always text + icon, never colour alone.
    final chip = switch (e.state) {
      MyEntitlementState.active => const PlengoChip(label: 'فعّال', hue: PlengoColors.green, icon: Icons.check_rounded),
      MyEntitlementState.expired => PlengoChip(
        label: 'منتهي',
        icon: Icons.history_rounded,
        background: s.track,
        foreground: s.mute,
      ),
      MyEntitlementState.revoked => const PlengoChip(label: 'ملغى', hue: PlengoColors.red, icon: Icons.block_rounded),
    };
    final hue = isTrack ? PlengoColors.pink : PlengoColors.blue;
    return ListRow(
      leading: active
          ? SubjectIconTile(icon: isTrack ? Icons.person_pin_rounded : Icons.menu_book_rounded, hue: hue)
          : Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: s.track, borderRadius: BorderRadius.circular(PlengoRadius.iconTile)),
              child: Icon(isTrack ? Icons.person_pin_rounded : Icons.menu_book_rounded, color: s.mute),
            ),
      title: scopeTitle(e.scope),
      caption: '${scopeSubtitle(e.scope)}\n${termLabel(isPermanent: e.isPermanent, expiresAt: e.expiresAt)}',
      trailing: chip,
      onTap: () => context.go(
        isTrack ? '${Routes.tracks}/${e.scope.teacherTrackId}' : '${Routes.subjects}/${e.scope.subjectId}',
      ),
    );
  }
}
