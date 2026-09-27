import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
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
      appBar: AppBar(title: const Text('صلاحيات الوصول')),
      floatingActionButton: redeem
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Routes.redeem),
              icon: const Icon(Icons.vpn_key_outlined),
              label: const Text('إدخال كود التفعيل'),
            )
          : null,
      body: AsyncView(
        value: entitlements,
        onRetry: () => ref.invalidate(myEntitlementsProvider),
        data: (items) => items.isEmpty
            ? const EmptyState('لا توجد صلاحيات وصول بعد', icon: Icons.key_off_outlined)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(myEntitlementsProvider.future),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      children: [for (final e in items) _EntitlementCard(entitlement: e)],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _EntitlementCard extends StatelessWidget {
  const _EntitlementCard({required this.entitlement});

  final MyEntitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final e = entitlement;
    final scheme = Theme.of(context).colorScheme;
    final active = e.state == MyEntitlementState.active;
    final isTrack = e.scope.scopeType == AccessScopeScopeType.teacherTrack;
    final (label, color) = switch (e.state) {
      MyEntitlementState.active => ('فعّال', scheme.primary),
      MyEntitlementState.expired => ('منتهي', scheme.outline),
      MyEntitlementState.revoked => ('ملغى', scheme.error),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isTrack ? Icons.person_pin_outlined : Icons.menu_book_outlined,
          color: active ? null : scheme.outline,
        ),
        title: Text(scopeTitle(e.scope)),
        subtitle: Text('${scopeSubtitle(e.scope)}\n${termLabel(isPermanent: e.isPermanent, expiresAt: e.expiresAt)}'),
        isThreeLine: true,
        trailing: Chip(
          label: Text(label),
          labelStyle: TextStyle(color: color),
          side: BorderSide(color: color),
          visualDensity: VisualDensity.compact,
        ),
        onTap: () => context.go(
          isTrack ? '${Routes.tracks}/${e.scope.teacherTrackId}' : '${Routes.subjects}/${e.scope.subjectId}',
        ),
      ),
    );
  }
}
